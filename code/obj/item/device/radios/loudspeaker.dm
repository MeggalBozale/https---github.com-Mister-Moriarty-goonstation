TYPEINFO(/obj/item/device/radio/intercom/loudspeaker)
	mats = 0

/obj/item/device/radio/intercom/loudspeaker
	name = "Loudspeaker Transmitter"
	icon = 'icons/obj/loudspeakers.dmi'
	icon_state = "transmitter"
	anchored = ANCHORED
	speaker_range = 1
	chat_class = RADIOCL_INTERCOM
	start_listen_inputs = null
	microphone_listen_input = LISTEN_INPUT_OUTLOUD_RANGE_1
	initial_microphone_enabled = FALSE
	initial_speaker_enabled = FALSE
	density = 1
	rand_pos = 0
	desc = "A HAM radio transmitter...Basically...It only transmits to loudspeakers on a secure frequency."
	frequency = R_FREQ_LOUDSPEAKERS

/obj/item/device/radio/intercom/loudspeaker/initialize()
	src.set_frequency(frequency)

	if (length(src.secure_frequencies))
		src.set_secure_frequencies()

/obj/item/device/radio/intercom/loudspeaker/examine()
	. = ..()
	. += "[src] is[src.microphone_enabled ? " " : " not "]active!\nIt is tuned to [format_frequency(src.frequency)]Hz."

/obj/item/device/radio/intercom/loudspeaker/attack_self(mob/user)
	if (!src.microphone_enabled)
		src.toggle_microphone(TRUE)
		src.icon_state = "transmitter-on"
		boutput(user, "Now transmitting.")
	else
		src.toggle_microphone(FALSE)
		src.icon_state = "transmitter"
		boutput(user, "No longer transmitting.")


TYPEINFO(/obj/item/device/radio/intercom/loudspeaker/speaker)
	mats = 0

/obj/item/device/radio/intercom/loudspeaker/speaker
	name = "Loudspeaker"
	icon_state = "loudspeaker"
	anchored = ANCHORED
	speaker_range = 7
	voice_sound_override = 'sound/misc/talk/speak_1.ogg'
	initial_microphone_enabled = FALSE
	initial_speaker_enabled = TRUE
	chat_class = RADIOCL_INTERCOM
	frequency = R_FREQ_LOUDSPEAKERS
	rand_pos = 0
	density = 0
	desc = "A Loudspeaker."

/obj/item/device/radio/intercom/loudspeaker/speaker/New()
	. = ..()

	if ((src.pixel_x != 0) || (src.pixel_y != 0))
		return

	switch(src.dir)
		if (NORTH)
			src.pixel_y = -14
		if (SOUTH)
			src.pixel_y = 32
		if (EAST)
			src.pixel_x = -21
		if (WEST)
			src.pixel_x = 21

/obj/item/device/radio/intercom/loudspeaker/speaker/hear()
	return

/obj/item/device/radio/intercom/loudspeaker/speaker/receive_signal()
	. = ..()

	if (.)
		return

	flick("loudspeaker-transmitting", src)

/obj/item/device/radio/intercom/loudspeaker/speaker/attack_self(mob/user)
	return

/obj/item/device/radio/intercom/loudspeaker/speaker/attack_hand(mob/user)
	return


/obj/item/device/radio/intercom/loudspeaker/speaker/north
	dir = NORTH
/obj/item/device/radio/intercom/loudspeaker/speaker/south
	dir = SOUTH
/obj/item/device/radio/intercom/loudspeaker/speaker/east
	dir = EAST
/obj/item/device/radio/intercom/loudspeaker/speaker/west
	dir = WEST
