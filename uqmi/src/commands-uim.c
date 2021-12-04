/*
 * uqmi -- tiny QMI support implementation
 *
 * Copyright (C) 2016 Felix Fietkau <nbd@nbd.name>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

#define cmd_uim_verify_pin1_cb no_cb
static enum qmi_cmd_result
cmd_uim_verify_pin1_prepare(struct qmi_dev *qmi, struct qmi_request *req, struct qmi_msg *msg, char *arg)
{
	struct qmi_uim_verify_pin_request data = {
		QMI_INIT_SEQUENCE(session,
			.session_type = QMI_UIM_SESSION_TYPE_CARD_SLOT_1,
			.application_identifier_n = 0
		),
		QMI_INIT_SEQUENCE(info,
			.pin_id = QMI_UIM_PIN_ID_PIN1,
			.pin_value = arg
		)
	};
	qmi_set_uim_verify_pin_request(msg, &data);
	return QMI_CMD_REQUEST;
}

#define cmd_uim_verify_pin2_cb no_cb
static enum qmi_cmd_result
cmd_uim_verify_pin2_prepare(struct qmi_dev *qmi, struct qmi_request *req, struct qmi_msg *msg, char *arg)
{
	struct qmi_uim_verify_pin_request data = {
		QMI_INIT_SEQUENCE(session,
			.session_type = QMI_UIM_SESSION_TYPE_CARD_SLOT_1,
			.application_identifier_n = 0
		),
		QMI_INIT_SEQUENCE(info,
			.pin_id = QMI_UIM_PIN_ID_PIN2,
			.pin_value = arg
		)
	};
	qmi_set_uim_verify_pin_request(msg, &data);
	return QMI_CMD_REQUEST;
}

static void cmd_uim_get_sim_state_cb(struct qmi_dev *qmi, struct qmi_request *req, struct qmi_msg *msg)
{
	struct qmi_uim_get_card_status_response res;
	void * const card_table = blobmsg_open_table(&status, NULL);

	qmi_parse_uim_get_card_status_response(msg, &res);

	for (int i = 0; i < res.data.card_status.cards_n; ++i) {
		if (res.data.card_status.cards[i].card_state != QMI_UIM_CARD_STATE_PRESENT)
			continue;

		uint8_t pin1_state = res.data.card_status.cards[i].upin_state;
		uint8_t pin1_retries = res.data.card_status.cards[i].upin_retries;
		uint8_t puk1_retries = res.data.card_status.cards[i].upuk_retries;
		uint8_t pin2_state;
		uint8_t pin2_retries;
		uint8_t puk2_retries;
		bool has_pin2 = false;

		for (int j = 0; j < res.data.card_status.cards[i].applications_n; ++j) {
			if (res.data.card_status.cards[i].applications[j].type == QMI_UIM_CARD_APPLICATION_TYPE_UNKNOWN)
				continue;

			if (!res.data.card_status.cards[i].applications[j].upin_replaces_pin1) {
				pin1_state = res.data.card_status.cards[i].applications[j].pin1_state;
				pin1_retries = res.data.card_status.cards[i].applications[j].pin1_retries;
				puk1_retries = res.data.card_status.cards[i].applications[j].puk1_retries;
			}

			pin2_state = res.data.card_status.cards[i].applications[j].pin2_state;
			pin2_retries = res.data.card_status.cards[i].applications[j].pin2_retries;
			puk2_retries = res.data.card_status.cards[i].applications[j].puk2_retries;
			has_pin2 = true;

			break; /* handle first application only for now */
		}

		blobmsg_add_string(&status, "pin1_status", get_pin_status(pin1_state));
		blobmsg_add_u32(&status, "pin1_verify_tries", pin1_retries);
		blobmsg_add_u32(&status, "pin1_unlock_tries", puk1_retries);
		if (has_pin2) {
			blobmsg_add_string(&status, "pin2_status", get_pin_status(pin2_state));
			blobmsg_add_u32(&status, "pin2_verify_tries", pin2_retries);
			blobmsg_add_u32(&status, "pin2_unlock_tries", puk2_retries);
		}

		break; /* handle only first preset SIM card for now */
	}

	blobmsg_close_table(&status, card_table);
}

static enum qmi_cmd_result
cmd_uim_get_sim_state_prepare(struct qmi_dev *qmi, struct qmi_request *req, struct qmi_msg *msg, char *arg)
{
	qmi_set_uim_get_card_status_request(msg);
	return QMI_CMD_REQUEST;
}
