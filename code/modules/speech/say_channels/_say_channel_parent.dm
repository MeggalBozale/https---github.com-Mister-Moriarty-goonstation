ABSTRACT_TYPE(/datum/say_channel)
/**
 *	Say channel datums govern the dissemination of messages to registered listen input module datums. In its simplest form, this
 *	involves a say message datum being passed from an output module to a channel, and the channel then performing shared input
 *	formatting before passing the say message to registered listen modules. Say channels also determine whether a message should
 *	be affected by output and input modifiers, and whether the sender should display a speech bubble and play a speech sound.
 */
/datum/say_channel
	/// This channel datum's channel ID.
	var/channel_id = null
	/// An associative list of listeners registered to this channel, indexed by input module type.
	var/list/list/datum/listen_module/input/listeners
	/// Whether messages sent through this channel should be affected by say or listen modifiers.
	var/affected_by_modifiers = TRUE
	/// Whether the speaker of a message sent through this channel should make a sound on sending a message.
	var/suppress_say_sound = FALSE
	/// Whether recipients of messages sent through this channel should hear a sound on receiving a message.
	var/suppress_hear_sound = FALSE
	/// Whether the speaker of a message sent through this channel should display a speech bubble on sending a message.
	var/suppress_speech_bubble = FALSE

/datum/say_channel/New()
	. = ..()

	src.listeners = list()

/// The primary entry point for say message datums; they will be passed to this channel through this proc.
/datum/say_channel/proc/PassToChannel(datum/say_message/message)
	src.PassToListeners(message, src.listeners)

/// Pass a message to all listen modules in a specified list, indexed in sublists by type.
/datum/say_channel/proc/PassToListeners(datum/say_message/message, list/list/datum/listen_module/input/listen_modules_by_type)
	for (var/datum/listen_module/input/type as anything in listen_modules_by_type)
		var/datum/say_message/module_message = message.Copy()
		var/datum/shared_input_format_module/format_module = global.SpeechManager.GetSharedInputFormatModuleInstance(initial(type.id))
		if (format_module)
			format_module.process(module_message)
			if (QDELETED(module_message))
				continue

		for (var/datum/listen_module/input/heard as anything in listen_modules_by_type[type])
			if (QDELETED(heard))
				listen_modules_by_type[type] -= heard
				continue

			if (module_message.atom_listeners_to_be_excluded && module_message.atom_listeners_to_be_excluded[heard.parent_tree.parent])
				continue

			heard.process(module_message.Copy())

/// A secondary entry point for say message datums; they will not be passed over this channel conventionally, but rather disseminated to a stored list of atom listeners.
/datum/say_channel/proc/PassToOverriddenAtomListeners(datum/say_message/message)
	src.log_message(message)

	var/list/list/datum/listen_module/input/listen_modules_by_type = list()
	for (var/atom/A as anything in message.atom_listeners_override)
		if (!A.listen_tree)
			continue

		for (var/datum/listen_module/input/input as anything in A.listen_tree.input_modules_by_channel[src.channel_id])
			listen_modules_by_type[input.type] ||= list()
			listen_modules_by_type[input.type] += input

	for (var/datum/listen_module/input/type as anything in listen_modules_by_type)
		var/datum/say_message/module_message = message.Copy()
		var/datum/shared_input_format_module/format_module = global.SpeechManager.GetSharedInputFormatModuleInstance(initial(type.id))
		if (format_module)
			format_module.process(module_message)
			if (QDELETED(module_message))
				continue

		for (var/datum/listen_module/input/heard as anything in listen_modules_by_type[type])
			if (QDELETED(heard))
				continue

			heard.process(module_message.Copy())

/// If a message was spoken by a client, logs the message.
/datum/say_channel/proc/log_message(datum/say_message/message)
	var/mob/M = message.speaker
	if (!istype(M) || !M.client || !(message.flags & SAYFLAG_SPOKEN_BY_PLAYER))
		return

	logTheThing(LOG_SAY, message.speaker, "([src.channel_id]): [message.content]")
	phrase_log.log_phrase("say", message.content)


/// Register a listener for hearing messages on a channel.
/datum/say_channel/proc/RegisterInput(datum/listen_module/input/registree)
	src.listeners[registree.type] ||= list()
	src.listeners[registree.type] += registree

/// Unregister a listener so it no longer receieves messages from this channel.
/datum/say_channel/proc/UnregisterInput(datum/listen_module/input/registered)
	src.listeners[registered.type] -= registered





ABSTRACT_TYPE(/datum/say_channel/global_channel)
/**
 *	Global say channel datums act as optional parters to delimited say channels, with the delimited channel passing all messages
 *	sent over it, irrespective of subchannel or range, to the global channel. In turn, any message sent to the global channel will
 *	be sent to all listeners on the delimited channel, irrespective of subchannel or range.
 */
/datum/say_channel/global_channel
	/// The channel ID of this global channel's partner delimited channel.
	var/delimited_channel_id
	/// This global channel datum's partner delimited channel datum. All messages sent through this channel will be sent to every listener on the delimited channel.
	var/datum/say_channel/delimited/delimited_channel

/datum/say_channel/global_channel/New()
	. = ..()

	SPAWN(0)
		src.delimited_channel = global.SpeechManager.GetSayChannelInstance(src.delimited_channel_id)
		delimited_channel.global_channel = src

/datum/say_channel/global_channel/PassToChannel(datum/say_message/message, from_delimited_channel = FALSE)
	. = ..()

	if (from_delimited_channel)
		return

	src.delimited_channel.PassToListeners(message, src.delimited_channel.listeners, TRUE)

/datum/say_channel/global_channel/log_message()
	return





ABSTRACT_TYPE(/datum/say_channel/delimited)
/**
 *	Delimited say channel datums, by some criteria, restrict the number of listeners that a say message is passed to. This typically
 *	manifests as only sending messages to listeners within a range of the speaker, or only sending messages to listeners registered
 *	to a specific subchannel. A global say channel datum may be associated with a delimited channel, which will receive all messages
 *	sent over the delimited channel and in turn may send messages to all listeners. See `/datum/say_channel/global_channel`.
 */
/datum/say_channel/delimited
	/// This delimited channel datum's partner global channel datum. All messages sent through this channel are also sent to the global channel.
	var/datum/say_channel/global_channel/global_channel

/datum/say_channel/delimited/PassToListeners(datum/say_message/message, list/list/datum/listen_module/input/listen_modules_by_type, from_global_channel = FALSE)
	. = ..(message, listen_modules_by_type)

	if (!src.global_channel || from_global_channel || (message.flags & SAYFLAG_DELIMITED_CHANNEL_ONLY))
		return

	src.global_channel.PassToChannel(message, TRUE)





ABSTRACT_TYPE(/datum/say_channel/delimited/local)
/**
 *	Local say channels are a form of delimited channel that restrict the number of listeners that a say message is passed to on the
 *	basis of range. How this range is calculated may be altered by overriding `GetAtomListeners()`.
 */
/datum/say_channel/delimited/local

/datum/say_channel/delimited/local/PassToChannel(datum/say_message/message)
	var/list/list/datum/listen_module/input/listen_modules_by_type = list()
	for (var/atom/A as anything in src.GetAtomListeners(message))
		if (!A.listen_tree)
			continue

		for (var/datum/listen_module/input/input as anything in A.listen_tree.input_modules_by_channel[src.channel_id])
			listen_modules_by_type[input.type] ||= list()
			listen_modules_by_type[input.type] += input

	src.PassToListeners(message, listen_modules_by_type)

/datum/say_channel/delimited/local/proc/GetAtomListeners(datum/say_message/message)
	RETURN_TYPE(/list/atom)
	return range(message.heard_range, message.speaker)





ABSTRACT_TYPE(/datum/say_channel/delimited/bundled)
/**
 *	Bundled say channels are a form of delimited channel that restrict the number of listeners that a say message is passed to on
 *	the basis of which subchannel a listener is registered to. Unlike say channel IDs, subchannel IDs may be defined arbitrarily at
 *	runtime; subchannel IDs are commonly BYOND atom references to some shared datum among listeners.
 */
/datum/say_channel/delimited/bundled
	/// A list of subchannels, each an associative list of listeners registered to that subchannel, indexed by input module type.
	var/list/list/list/datum/listen_module/input/listeners_by_subchannel

/datum/say_channel/delimited/bundled/New()
	. = ..()

	src.listeners_by_subchannel = list()

/datum/say_channel/delimited/bundled/PassToChannel(datum/say_message/message, subchannel)
	src.PassToListeners(message, src.listeners_by_subchannel[subchannel])

/datum/say_channel/delimited/bundled/RegisterInput(datum/listen_module/input/bundled/registree)
	. = ..()

	src.listeners_by_subchannel[registree.subchannel] ||= list()
	src.listeners_by_subchannel[registree.subchannel][registree.type] ||= list()
	src.listeners_by_subchannel[registree.subchannel][registree.type] += registree

/datum/say_channel/delimited/bundled/UnregisterInput(datum/listen_module/input/bundled/registered)
	. = ..()

	src.listeners_by_subchannel[registered.subchannel][registered.type] -= registered
