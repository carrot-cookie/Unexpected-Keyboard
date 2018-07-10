(** Functions that transform Key_value.t *)

open Android_view
open Key

type t = value -> value

(** Do nothing *)
let default k = k

(** Transforms chars to upper case, adds meta_shift flag on events *)
let shift =
	let meta_shift = Key_event.(get'meta_shift_left_on () lor get'meta_shift_on ()) in
	function
	| Char (c, _)		-> Char (Java_lang.Character.to_upper_case c, 0)
	| Event (kv, meta)	-> Event (kv, meta lor meta_shift)
	| kv				-> kv

(** Adds meta flags *)
let meta meta =
	function
	| Char (c, m')	-> Char (c, m' lor meta)
	| Event (e, m')	-> Event (e, m' lor meta)
	| kv			-> kv

let ctrl = meta Key_event.(get'meta_ctrl_left_on () lor get'meta_ctrl_on ())
let alt = meta Key_event.(get'meta_alt_left_on () lor get'meta_alt_on ())

(** Adds accents to chars that support it *)
let accent acc =
	let dead_char =
		match acc with
		| Acute		-> 0x00B4
		| Grave			-> 0x0060
		| Circumflex	-> 0x005E
		| Tilde			-> 0x007E
		| Cedilla		-> 0x00B8
		| Trema			-> 0x00A8
	in
	function
	| Char (c, meta) as kv	->
		begin match Key_character_map.get_dead_char dead_char c with
			| 0		-> kv
			| c		-> Char (c, meta)
		end
	| kv					-> kv

module Stack =
struct

	(** Store activated modifiers
		Modifiers are associated to the key that activated them *)

	type modifier = t
	type t = (value * modifier) list

	let empty = []

	(** Add a modifier on top of the stack *)
	let add key modifier t = (key, modifier) :: t

	(** Add a modifier like `add`
		Except if a modifier associated with the same key is already activated,
			it is simply removed, and no modifier is added *)
	let add_or_cancel key modifier t =
		if List.mem_assoc key t
		then List.remove_assoc key t
		else add key modifier t

	(** Apply the modifiers to the key
		Starting from the last added *)
	let apply t k =
		List.fold_left (fun k (_, m) -> m k) k t

end
