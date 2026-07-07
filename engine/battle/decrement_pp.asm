DecrementPP:
; after using a move, decrement pp in battle and (if not transformed?) in party
	ld a, [de]
	cp a, STRUGGLE
	ret z                ; if the pokemon is using "struggle", there's nothing to do
	                     ; we don't decrement PP for "struggle"
	ld hl, wPlayerBattleStatus1
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn
	ld hl, wEnemyBattleStatus1
.playersTurn
	ld a, [hli]          ; load the wPlayerBattleStatus1 pokemon status flags and increment hl to load the
	                     ; wPlayerBattleStatus2 status flags later
	and a, (1 << StoringEnergy) | (1 << ThrashingAbout) | (1 << AttackingMultipleTimes)
	ret nz               ; if any of these statuses are true, don't decrement PP
	bit UsingRage, [hl]
	ret nz               ; don't decrement PP either if Pokemon is using Rage
	ld hl, wBattleMonPP  ; PP of first move (in battle)
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn2
	ld hl, wEnemyMonPP
.playersTurn2

; decrement PP in the battle struct
	call .DecrementPP

; decrement PP in the party struct
	ld hl, wPlayerBattleStatus3
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn3
	ld hl, wPlayerBattleStatus3
.playersTurn3
	ld a, [hl]
	bit Transformed, a
	ret nz               ; Return if transformed. Pokemon Red stores the "current pokemon's" PP
	                     ; separately from the "Pokemon in your party's" PP.  This is
	                     ; duplication -- in all cases *other* than Pokemon with Transform.
	                     ; Normally, this means we have to go on and make the same
	                     ; modification to the "party's pokemon" PP that we made to the
	                     ; "current pokemon's" PP.  But, if we're dealing with a Transformed
	                     ; Pokemon, it has separate PP for the move set that it copied from
	                     ; its opponent, which is *not* the same as its real PP as part of your
	                     ; party.  So we return, and don't do that part.

;if wild AND ENEMY'S TURN, do not decrement Enemy Party PP
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn7
	ld a, [wIsInBattle]
	dec a ; is it a wild battle?
	ret z
.playersTurn7

	ld hl, wPartyMon1PP  ; PP of first move (in party)
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn4
	ld hl, wEnemyMon1PP
.playersTurn4

	push hl
	ld hl, wPlayerMonNumber ; which mon in party is active
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn5
	ld hl, wEnemyMonPartyPos
.playersTurn5
	ld a, [hl]
	pop hl

	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes       ; calculate address of the mon to modify
.DecrementPP:
	push hl
	ld hl, wPlayerMoveListIndex ; which move (0, 1, 2, 3) did we use?
	ldh a, [H_WHOSETURN]
	and a
	jr z, .playersTurn6
	ld hl, wEnemyMoveListIndex
.playersTurn6
	ld a, [hl]
	pop hl
	ld c, a
	ld b, 0
	add hl ,bc           ; calculate the address in memory of the PP we need to decrement
	                     ; based on the move chosen.
	dec [hl]             ; Decrement PP
	ret
