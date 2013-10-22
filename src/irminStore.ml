(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
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

module type S = sig
  type key
  type value
  val write: value -> key Lwt.t
  val read: key -> value option Lwt.t
end

module type RAW = S
  with type key := string
   and type value := IrminBuffer.t

module Make (S: RAW) (K: IrminKey.S) (V: IrminBase.S) = struct

  open Lwt

  type key = K.t

  type value = V.t

  let read k =
    let key = K.dump k in
    S.read key >>= function
    | None   -> Lwt.return None
    | Some b -> Lwt.return (Some (V.get b))

  let key v =
    K.create (V.dump v)

  let write v =
    let buf = IrminBuffer.create (V.sizeof v) in
    V.set buf v;
    S.write buf >>= fun k ->
    return (K.create k)

end
