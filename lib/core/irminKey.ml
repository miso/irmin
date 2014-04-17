(*
 * Copyright (c) 2013-2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Core_kernel.Std

exception Invalid of string
exception Unknown of string

module type S = sig
  include Identifiable.S

  val of_raw: string -> t
  val to_raw: t -> string
  val to_json: t -> Ezjsonm.t
  val of_json: Ezjsonm.t -> t
  val of_bytes: Cstruct.buffer -> t
  val of_bytes': string -> t

end

module SHA1 = struct

  module Log = Log.Make(struct let section = "SHA1" end)

  let to_hex t =
    IrminMisc.hex_encode t

  let of_hex hex =
    IrminMisc.hex_decode hex

  module M = struct
    type t = string
    with bin_io, compare, sexp
    let hash (t : t) = Hashtbl.hash t
    let sexp_of_t t =
      Sexplib.Sexp.Atom (to_hex t)
    let t_of_sexp s =
      of_hex (Sexplib.Conv.string_of_sexp s)
    include Sexpable.To_stringable (struct type nonrec t = t with sexp end)
    let module_name = "Key"
  end
  include M
  include Identifiable.Make (M)

  let len = 20

  let of_raw str =
    if Int.(String.length str = len) then str
    else raise (Invalid str)

  let to_raw str =
    str

  let to_json t =
    Ezjsonm.string (to_hex t)

  let of_json j =
    of_hex (Ezjsonm.get_string j)

  (* |-----|-------------| *)
  (* | 'K' | PAYLOAD(20) | *)
  (* |-----|-------------| *)

  let header = "K"

  let sizeof _ =
    1 + len

  let get buf =
    Log.debug (lazy "get");
    let h = Mstruct.get_string buf 1 in
    if header <> h then None
    else
      try
        let str = Mstruct.get_string buf len in
        Log.debugf "--> get %s" (to_string str);
        Some str
      with _ ->
        None

  let set buf t =
    Log.debugf "set %s" (to_string t);
    Mstruct.set_string buf header;
    Mstruct.set_string buf t

  let of_bytes' str =
    Log.debugf "of_bytes: %S" str;
    IrminMisc.sha1 str

  let of_bytes ba =
    Log.debugf "of_bigarray";
    (* XXX: avoid copies *)
    of_bytes' (Bigstring.to_string ba)

end
