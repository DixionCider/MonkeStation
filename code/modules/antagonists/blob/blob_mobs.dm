
////////////////
// BASE TYPE //
////////////////

//Do not spawn
/mob/living/simple_animal/hostile/blob
	icon = 'icons/mob/blob.dmi'
	pass_flags = PASSBLOB
	faction = list(ROLE_BLOB)
	bubble_icon = "blob"
	speak_emote = null //so we use verb_yell/verb_say/etc
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 360
	unique_name = 1
	a_intent = INTENT_HARM
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	initial_language_holder = /datum/language_holder/empty
	var/mob/camera/blob/overmind = null
	var/obj/structure/blob/factory/factory = null
	var/independent = FALSE
	mobchatspan = "blob"
	discovery_points = 1000

/mob/living/simple_animal/hostile/blob/update_icons()
	if(overmind)
		add_atom_colour(overmind.blobstrain.color, FIXED_COLOUR_PRIORITY)
	else
		remove_atom_colour(FIXED_COLOUR_PRIORITY)

/mob/living/simple_animal/hostile/blob/Initialize(mapload)
	. = ..()
	if(!independent) //no pulling people deep into the blob
		remove_verb(/mob/living/verb/pulled)
	else
		pass_flags &= ~PASSBLOB

/mob/living/simple_animal/hostile/blob/Destroy()
	if(overmind)
		overmind.blob_mobs -= src
	return ..()

/mob/living/simple_animal/hostile/blob/blob_act(obj/structure/blob/B)
	if(stat != DEAD && health < maxHealth)
		for(var/i in 1 to 2)
			var/obj/effect/temp_visual/heal/H = new /obj/effect/temp_visual/heal(get_turf(src)) //hello yes you are being healed
			if(overmind)
				H.color = overmind.blobstrain.complementary_color
			else
				H.color = "#000000"
		adjustHealth(-maxHealth*0.0125)

/mob/living/simple_animal/hostile/blob/fire_act(exposed_temperature, exposed_volume)
	..()
	if(exposed_temperature)
		adjustFireLoss(CLAMP(0.01 * exposed_temperature, 1, 5))
	else
		adjustFireLoss(5)

/mob/living/simple_animal/hostile/blob/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /obj/structure/blob))
		return TRUE

/mob/living/simple_animal/hostile/blob/Process_Spacemove(movement_dir = 0)
	for(var/obj/structure/blob/B in range(1, src))
		return 1
	return ..()

/mob/living/simple_animal/hostile/blob/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!overmind)
		return ..()
	var/spanned_message = say_quote(message)
	var/rendered = "<font color=\"#EE4000\"><b>\[Blob Telepathy\] [real_name]</b> [spanned_message]</font>"
	for(var/M in GLOB.mob_list)
		if(isovermind(M) || istype(M, /mob/living/simple_animal/hostile/blob))
			to_chat(M, rendered)
		if(isobserver(M))
			var/link = FOLLOW_LINK(M, src)
			to_chat(M, "[link] [rendered]")

////////////////
// BLOB SPORE //
////////////////

/mob/living/simple_animal/hostile/blob/blobspore
	name = "blob spore"
	desc = "A floating, fragile spore."
	icon_state = "blobpod"
	icon_living = "blobpod"
	health = 30
	maxHealth = 30
	verb_say = "psychically pulses"
	verb_ask = "psychically probes"
	verb_exclaim = "psychically yells"
	verb_yell = "psychically screams"
	melee_damage = 4
	obj_damage = 20
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attacktext = "hits"
	attack_sound = 'sound/weapons/genhit1.ogg'
	movement_type = FLYING
	del_on_death = TRUE
	deathmessage = "explodes into a cloud of gas!"
	gold_core_spawnable = HOSTILE_SPAWN
	move_to_delay = 6
	var/death_cloud_size = 1 //size of cloud produced from a dying spore
	var/mob/living/carbon/human/oldguy
	var/is_zombie = FALSE
	var/list/disease = list()
	flavor_text = FLAVOR_TEXT_GOAL_ANTAG
	var/in_movement //only for rally command so blob spores will stop chasing after that one guy and get to the rally point

/mob/living/simple_animal/hostile/blob/blobspore/Initialize(mapload, var/obj/structure/blob/factory/linked_node)
	if(istype(linked_node))
		factory = linked_node
		factory.spores += src
	. = ..()
	/*var/datum/disease/advance/random/blob/R = new //either viro is cooperating with xenobio, or a blob has spawned and the round is probably over sooner than they can make a virus for this
	disease += R*/

/mob/living/simple_animal/hostile/blob/blobspore/extrapolator_act(mob/user, var/obj/item/extrapolator/E, scan = TRUE)
	if(scan)
		E.scan(src, disease, user)
	else
		if(E.create_culture(disease, user))
			dust()
			user.visible_message("<span class='danger'>[user] stabs [src] with [E], sucking it up!</span>", \
	 				 "<span class='danger'>You stab [src] with [E]'s probe, destroying it!</span>")
	return TRUE

/mob/living/simple_animal/hostile/blob/blobspore/Life()
	if(!is_zombie && isturf(src.loc))
		for(var/mob/living/carbon/human/H in hearers(1, src)) //Only for corpse right next to/on same tile
			if(H.stat == DEAD)
				Zombify(H)
				break
	if(factory && z != factory.z)
		death()
	..()

/mob/living/simple_animal/hostile/blob/blobspore/proc/Zombify(mob/living/carbon/human/H)
	is_zombie = 1
	if(H.wear_suit)
		var/obj/item/clothing/suit/armor/A = H.wear_suit
		maxHealth += A.armor.melee //That zombie's got armor, I want armor!
	maxHealth += 40
	health = maxHealth
	name = "blob zombie"
	desc = "A shambling corpse animated by the blob."
	mob_biotypes += MOB_HUMANOID
	melee_damage += 11
	movement_type = GROUND
	death_cloud_size = 0
	icon = H.icon
	icon_state = "zombie"
	H.hair_style = null
	H.update_hair()
	H.forceMove(src)
	oldguy = H
	update_icons()
	visible_message("<span class='warning'>The corpse of [H.name] suddenly rises!</span>")
	if(!key)
		set_playable()

/mob/living/simple_animal/hostile/blob/blobspore/death(gibbed)
	// On death, create a small smoke of harmful gas (s-Acid)
	var/datum/effect_system/smoke_spread/chem/S = new
	var/turf/location = get_turf(src)

	// Create the reagents to put into the air
	create_reagents(10)



	if(overmind?.blobstrain)
		overmind.blobstrain.on_sporedeath(src)
	else
		reagents.add_reagent(/datum/reagent/toxin/spore, 10)

	// Attach the smoke spreader and setup/start it.
	S.attach(location)
	S.set_up(reagents, death_cloud_size, location, silent = TRUE)
	S.start()
	if(factory)
		factory.spore_delay = world.time + factory.spore_cooldown //put the factory on cooldown

	..()

/mob/living/simple_animal/hostile/blob/blobspore/Destroy()
	if(factory)
		factory.spores -= src
	factory = null
	if(oldguy)
		oldguy.forceMove(get_turf(src))
		oldguy = null
	return ..()

/mob/living/simple_animal/hostile/blob/blobspore/update_icons()
	if(overmind)
		add_atom_colour(overmind.blobstrain.complementary_color, FIXED_COLOUR_PRIORITY)
	else
		remove_atom_colour(FIXED_COLOUR_PRIORITY)
	if(is_zombie)
		copy_overlays(oldguy, TRUE)
		var/mutable_appearance/blob_head_overlay = mutable_appearance('icons/mob/blob.dmi', "blob_head")
		if(overmind)
			blob_head_overlay.color = overmind.blobstrain.complementary_color
		color = initial(color)//looks better.
		add_overlay(blob_head_overlay)

/mob/living/simple_animal/hostile/blob/blobspore/Goto(target, delay, minimum_distance, rally, current_tries)
	var/movement_steps = 0
	if(rally)
		in_movement = TRUE

	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE
	var/list/path_list = get_path_to(src, target) //we want access to the list
	var/turf/goal_turf
	if(length(path_list)) //appearantly the solution of using ? infront of the index only works for assoc lists
		goal_turf = path_list[path_list.len]
	for(var/w in path_list)
		if(in_movement && !rally) //incase the spore is already chasing something like a player but the rally command is called
			return
		movement_steps++
		if(ismob(target) && w == goal_turf) //if we are infront of the mob lets not keep on pushing
			break
		sleep(delay)
		step(src, get_dir(src, w))
		if(get_turf(src) != w) //in case someone decides to push the spore or something else unexpectedly hinders it
			in_movement = FALSE
			if(current_tries >= 20)	//In case we get catched in a endless loop for reasons
				return
			else
				return Goto(target, delay, minimum_distance, rally, current_tries + 1)
		if(ismob(target) && !(get_turf(target) == goal_turf)) //Incase the target mob decides to move so we don't just run towards it's original location
			if(get_dist(path_list[1], get_turf(target)) >= 20)
				break
			else
				return Goto(target, delay, minimum_distance, rally)

	if(!movement_steps) //pathfinding fallback in case we cannot find a valid path at the first attempt
		var/ln = get_dist(src, target)
		var/turf/target_new = target
		var/found_blocker
		while(!movement_steps && (ln > 0)) //will stop if we can find a valid path or if ln gets reduced to 0 or less
			find_target:
				for(var/i in 1 to ln) //calling get_path_to every time is quite taxing lets see if we can find whatever blocks us
					target_new = get_step(target_new,  get_dir(target_new, src)) //step towards the origin until we find the blocker then 1 further
					ln--
					if(target_new.density && !(target_new.pass_flags_self & pass_flags)) //we check for possible tiles that could block us
						found_blocker = TRUE
						continue find_target //in case there is like a double wall
					for(var/obj/o in target_new.contents)
						if(o.density && !(o.pass_flags_self & pass_flags)) //We check for possible blockers on the tile
							found_blocker = TRUE
							continue find_target
					if(found_blocker) //cursed but after we found the blocker we end the loop on the next illiteration
						break find_target
			found_blocker = FALSE
			for(var/w in get_path_to(src, target_new))
				if(in_movement && !rally)
					return
				movement_steps++
				sleep(delay)
				step(src, get_dir(src, w))
				if(get_turf(src) != w)
					in_movement = FALSE
					if(current_tries >= 20)
						return
					else
						return Goto(target, delay, rally, (current_tries + 1))
	in_movement = FALSE

/mob/living/simple_animal/hostile/blob/blobspore/weak
	name = "fragile blob spore"
	health = 15
	maxHealth = 15
	melee_damage = 2
	death_cloud_size = 0

/////////////////
// BLOBBERNAUT //
/////////////////

/mob/living/simple_animal/hostile/blob/blobbernaut
	name = "blobbernaut"
	desc = "A hulking, mobile chunk of blobmass."
	icon_state = "blobbernaut"
	icon_living = "blobbernaut"
	icon_dead = "blobbernaut_dead"
	health = 200
	maxHealth = 200
	damage_coeff = list(BRUTE = 0.5, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	melee_damage = 20
	obj_damage = 60
	attacktext = "slams"
	attack_sound = 'sound/effects/blobattack.ogg'
	verb_say = "gurgles"
	verb_ask = "demands"
	verb_exclaim = "roars"
	verb_yell = "bellows"
	force_threshold = 10
	pressure_resistance = 50
	mob_size = MOB_SIZE_LARGE
	hud_type = /datum/hud/blobbernaut
	flavor_text = FLAVOR_TEXT_GOAL_ANTAG
	move_resist = MOVE_FORCE_STRONG

/mob/living/simple_animal/hostile/blob/blobbernaut/Life()
	if(..())
		var/list/blobs_in_area = range(2, src)
		if(independent)
			return // strong independent blobbernaut that don't need no blob
		var/damagesources = 0
		if(!(locate(/obj/structure/blob) in blobs_in_area))
			damagesources++
		if(!factory)
			damagesources++
		else
			if(locate(/obj/structure/blob/core) in blobs_in_area)
				adjustHealth(-maxHealth*0.1)
				var/obj/effect/temp_visual/heal/H = new /obj/effect/temp_visual/heal(get_turf(src)) //hello yes you are being healed
				if(overmind)
					H.color = overmind.blobstrain.complementary_color
				else
					H.color = "#000000"
			if(locate(/obj/structure/blob/node) in blobs_in_area)
				adjustHealth(-maxHealth*0.05)
				var/obj/effect/temp_visual/heal/H = new /obj/effect/temp_visual/heal(get_turf(src))
				if(overmind)
					H.color = overmind.blobstrain.complementary_color
				else
					H.color = "#000000"
		if(damagesources)
			for(var/i in 1 to damagesources)
				adjustHealth(maxHealth*0.025) //take 2.5% of max health as damage when not near the blob or if the naut has no factory, 5% if both
			var/image/I = new('icons/mob/blob.dmi', src, "nautdamage", MOB_LAYER+0.01)
			I.appearance_flags = RESET_COLOR
			if(overmind)
				I.color = overmind.blobstrain.complementary_color
			flick_overlay_view(I, src, 8)

/mob/living/simple_animal/hostile/blob/blobbernaut/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(updating_health)
		update_health_hud()

/mob/living/simple_animal/hostile/blob/blobbernaut/update_health_hud()
	if(hud_used)
		hud_used.healths.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#e36600'>[round((health / maxHealth) * 100, 0.5)]%</font></div>")

/mob/living/simple_animal/hostile/blob/blobbernaut/AttackingTarget()
	. = ..()
	if(. && isliving(target) && overmind)
		overmind.blobstrain.blobbernaut_attack(target)

/mob/living/simple_animal/hostile/blob/blobbernaut/update_icons()
	..()
	if(overmind) //if we have an overmind, we're doing chemical reactions instead of pure damage
		melee_damage = 4
		attacktext = overmind.blobstrain.blobbernaut_message
	else
		melee_damage = initial(melee_damage)
		attacktext = initial(attacktext)

/mob/living/simple_animal/hostile/blob/blobbernaut/death(gibbed)
	..(gibbed)
	if(factory)
		factory.naut = null //remove this naut from its factory
		factory.max_integrity = initial(factory.max_integrity)
	flick("blobbernaut_death", src)

/mob/living/simple_animal/hostile/blob/blobbernaut/independent
	independent = TRUE
	gold_core_spawnable = HOSTILE_SPAWN

