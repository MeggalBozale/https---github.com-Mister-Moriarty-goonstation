
/obj/item/device/microphone
	name = "microphone"
	icon = 'icons/obj/items/device.dmi'
	icon_state = "mic"
	item_state = "mic"

	start_listen_inputs = list(LISTEN_INPUT_OUTLOUD_RANGE_1)
	start_listen_languages = list(LANGUAGE_ALL)

	var/max_font = 8
	var/font_amp = 4
	var/on = 0

	get_desc()
		..()
		. += "It's currently [src.on ? "on" : "off"]."

	attack_self(mob/user as mob)
		src.on = !(src.on)
		tooltip_rebuild = 1
		user.show_text("You switch [src] [src.on ? "on" : "off"].")
		if (src.on && prob(5))
			if (locate(/obj/loudspeaker) in range(2, user))
				for_by_tcl(S, /obj/loudspeaker)
					if(!IN_RANGE(S, user, 7)) continue
					S.visible_message(SPAN_ALERT("[S] lets out a horrible [pick("shriek", "squeal", "noise", "squawk", "screech", "whine", "squeak")]!"))
					playsound(S.loc, 'sound/items/mic_feedback.ogg', 30, 1)

	attack_hand(mob/user)
		if (user.find_in_hand(src) && src.on)
			playsound(user, 'sound/misc/miccheck.ogg', 30, TRUE)
			user.visible_message(SPAN_EMOTE("[user] taps [src] with [his_or_her(user)] hand."))
		else
			return ..()

	hear(datum/say_message/message)
		if (!src.on || !CAN_RELAY_MESSAGE(message, SAY_RELAY_MICROPHONE))
			return

		var/feedback = FALSE
		var/list/obj/loudspeaker/loudspeakers = list()
		for_by_tcl(loudspeaker, /obj/loudspeaker)
			if (!IN_RANGE(src, loudspeaker, 7))
				continue

			if (IN_RANGE(src, loudspeaker, 2))
				feedback = TRUE

			loudspeakers += loudspeaker

		feedback &&= prob(10)

		message.message_size_override = clamp(length(loudspeakers) + src.font_amp, 0, src.max_font)
		message.output_module_channel = SAY_CHANNEL_OUTLOUD
		FORMAT_MESSAGE_FOR_RELAY(message, SAY_RELAY_MICROPHONE)

		for (var/obj/loudspeaker/loudspeaker as anything in loudspeakers)
			var/datum/say_message/loudspeaker_message = message.Copy()
			loudspeaker_message.speaker = loudspeaker
			loudspeaker.ensure_say_tree().process(loudspeaker_message)

			if (feedback)
				loudspeaker.visible_message(SPAN_ALERT("[loudspeaker] lets out a horrible [pick("shriek", "squeal", "noise", "squawk", "screech", "whine", "squeak")]!"))
				playsound(loudspeaker.loc, 'sound/items/mic_feedback.ogg', 30, 1)


TYPEINFO(/obj/mic_stand)
	mats = 10

/obj/mic_stand
	name = "microphone stand"
	icon = 'icons/obj/items/device.dmi'
	icon_state = "micstand"
	layer = FLY_LAYER

	start_listen_inputs = list(LISTEN_INPUT_OUTLOUD_RANGE_1)
	start_listen_languages = list(LANGUAGE_ALL)

	var/obj/item/device/microphone/myMic = null

	New()
		SPAWN(1 DECI SECOND)
			if (!myMic)
				myMic = new(src)
		return ..()

	attack_hand(mob/user)
		if (!myMic)
			return ..()
		user.put_in_hand_or_drop(myMic)
		myMic = null
		src.UpdateIcon()
		return ..()

	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/device/microphone))
			if (myMic)
				user.show_text("There's already a microphone on [src]!", "red")
				return
			user.show_text("You place [W] on [src].", "blue")
			myMic = W
			user.u_equip(W)
			W.set_loc(src)
			src.UpdateIcon()
		else
			return ..()

	hear(datum/say_message/message)
		src.myMic?.hear(message)

	update_icon()
		if (myMic)
			switch (myMic.icon_state)
				if ("radio_mic1")
					src.icon_state = "micstand-b"
				if ("radio_mic2")
					src.icon_state = "micstand-r"
				else
					src.icon_state = "micstand"
		else
			src.icon_state = "micstand-empty"

TYPEINFO(/obj/loudspeaker)
	mats = 15

/obj/loudspeaker
	name = "loudspeaker"
	icon = 'icons/obj/items/device.dmi'
	icon_state = "loudspeaker"
	anchored = ANCHORED
	density = 1
	deconstruct_flags = DECON_SCREWDRIVER | DECON_WRENCH | DECON_MULTITOOL

	New()
		. = ..()
		START_TRACKING

	disposing()
		. = ..()
		STOP_TRACKING
