(*
  Copyright (c) 2010, Mylife.com
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the
     distribution.

  3. Neither the name of Mylife.com nor the names of
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  JSON formatting section taken from Yojson
  (http://martin.jambon.free.fr/yojson.html):

  Copyright (c) 2010 Martin Jambon
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
  3. The name of the author may not be used to endorse or promote products
     derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

module Bio = Bi_outbuf
module Ef = Easy_format
module Y = Yojson

type json_withdiff =
      Null
    | Bool of bool
    | Int of int
    | Intlit of string
    | Float of float
    | String of string
    | Assoc of (string * json_withdiff) list
    | List of json_withdiff list
    | Tuple of json_withdiff list
    | Variant of (string * json_withdiff option)
    | Diff of (json_withdiff option * json_withdiff option)
    | DiffNumeric of int
    | DiffPercentage of int

module SD = Simple_diff.Make (struct
  type t = json_withdiff
  let compare = Stdlib.compare
end)

exception Json_error of string

(* JSON formatting, lots copied from Yojson. *)

let json_error s = raise (Json_error s)

let json_string_of_string s =
  let ob = Bio.create 10 in
  Y.write_string ob s;
  Bio.contents ob

let json_string_of_int i =
  string_of_int i

let json_string_of_float x =
  let ob = Bio.create 20 in
  Y.write_float ob x;
  Bio.contents ob

let std_json_string_of_float x =
  let ob = Bio.create 20 in
  Y.write_std_float ob x;
  Bio.contents ob

let array = Ef.list
let record = Ef.list
let tuple = { Ef.list with
                Ef.space_after_opening = false;
                Ef.space_before_closing = false;
                Ef.align_closing = false }
let variant = { Ef.list with
                  Ef.space_before_closing = false; }
let diff_color_solo =
  { Ef.list with
      Ef.space_after_opening = false;
      Ef.space_before_closing = false; }

let diff =
  { Ef.list with
      Ef.space_after_opening = true;
      Ef.align_closing = true;
      Ef.space_before_closing = true; }

let green_pre : string = "\027[32m"

let red_pre : string = "\027[31m"

let color_post : string = "\027[m"

let rec format color std x =
  match x with
    | Null -> Ef.Atom ("null", Ef.atom)
    | Bool x -> Ef.Atom ((if x then "true" else "false"), Ef.atom)
    | Int x -> Ef.Atom (json_string_of_int x, Ef.atom)
    | Float x ->
        let s =
          if std then std_json_string_of_float x
          else json_string_of_float x
        in
        Ef.Atom (s, Ef.atom)
    | String s -> Ef.Atom (json_string_of_string s, Ef.atom)
    | Intlit s -> Ef.Atom (s, Ef.atom)
    | List [] -> Ef.Atom ("[]", Ef.atom)
    | List l -> Ef.List (("[", ",", "]", array), List.map (format color std) l)
    | Assoc [] -> Ef.Atom ("{}", Ef.atom)
    | Assoc l -> Ef.List (("{", ",", "}", record),
                         List.map (format_field color std) l)
    | Tuple l ->
        if std then
          format color std (List l)
        else
          if l = [] then
            Ef.Atom ("()", Ef.atom)
          else
            Ef.List (("(", ",", ")", tuple), List.map (format color std) l)

    | Variant (s, None) ->
        if std then
          format color std (String s)
        else
          Ef.Atom ("<" ^ json_string_of_string s ^ ">", Ef.atom)

    | Variant (s, Some x) ->
        if std then
          format color std (List [ String s; x ])
        else
          let op = "<" ^ json_string_of_string s ^ ":" in
          Ef.List ((op, "", ">", variant), [format color std x])
    | Diff (None, None) -> failwith "Impossible in format."
    | Diff (None, Some j) ->
        if color then
          Ef.List ((green_pre, "", color_post, diff_color_solo),
                  [format color std j])
        else
          Ef.List (("[+", "", "+]", diff), [format color std j])
    | Diff (Some j, None) ->
        if color then
          Ef.List ((red_pre, "", color_post, diff_color_solo),
                  [format color std j])
        else
          Ef.List (("[-", "", "-]", diff), [format color std j])
    | Diff (Some j1, Some j2) ->
        if color then
          Ef.List (("[|" ^ red_pre, color_post ^ "," ^ green_pre,
                    color_post ^ "|]", diff),
                  [format color std j1; format color std j2])
        else
          Ef.List (("[|", ",", "|]", diff),
                  [format color std j1; format color std j2])
    | DiffNumeric x ->
        if color then
          if x > 0 then
          Ef.List ((green_pre, "", color_post, diff_color_solo),
                  [format color std (Int x)])
          else (* x < 0 *)
          Ef.List ((red_pre, "", color_post, diff_color_solo),
                  [format color std (Int x)])
        else
          if x > 0 then
            Ef.List (("[+", "", "+]", diff), [format color std (Int x)])
          else (* x < 0 *)
            Ef.List (("[-", "", "-]", diff), [format color std (Int x)])
    | DiffPercentage x ->
        if color then
          (* x can be zero because of rounding *)
          if x >= 0 then
          Ef.List ((green_pre, "", "%" ^ color_post, diff_color_solo),
                  [format color std (Int x)])
          else (* x < 0 *)
          Ef.List ((red_pre, "", "%" ^ color_post, diff_color_solo),
                  [format color std (Int x)])
        else
          if x > 0 then
            Ef.List (("[+", "", "% +]", diff), [format color std (Int x)])
          else (* x < 0 *)
            Ef.List (("[-", "", "% -]", diff), [format color std (Int x)])

and format_field color std (name, x) =
  let s = Printf.sprintf "%s:" (json_string_of_string name) in
  Ef.Label ((Ef.Atom (s, Ef.atom), Ef.label), format color std x)

let is_object_or_array x =
  match x with
      List _
    | Assoc _ -> true
    | _ -> false

let format ?(color = false) ?(std = false) x =
  if std && not (is_object_or_array x) then
    json_error
      "Root is not an object or array as requested by the JSON standard"
  else
    format color std (x :> json_withdiff)

let to_string ?color ?std x =
  Easy_format.Pretty.to_string (format ?color ?std x)

(* Utility functions *)

let id : 'a -> 'a = fun x -> x

let map2i path f xs ys =
  try
    List.map2 (fun x y -> x, y) xs ys
    |> List.mapi (fun i (x, y) -> f i x y)
  with Invalid_argument s ->
    raise (Invalid_argument (Format.asprintf "%s: %s" s (String.concat "/" path)))

let i2s = string_of_int

let option_map (f : 'a -> 'b) : 'a option -> 'b option = function
  | None -> None
  | Some x -> Some (f x)

let sort_assoc : ('a * 'b) list -> ('a * 'b) list =
  List.sort (fun (x1, _) (x2, _) -> compare x1 x2)

(* http://sds.podval.org/ocaml-sucks.html#library *)
let round (x : float) : int = int_of_float (floor (x +. 0.5))

let rec diff_assoc (path : string list)
                   (percentage : bool)
                   (numeric : bool)
                   (l : (string * json_withdiff) list)
                   (r : (string * json_withdiff) list)
                   : (string * json_withdiff) list =
  let l_sorted = sort_assoc l in
  let r_sorted = sort_assoc r
  in merge 0 path percentage numeric l_sorted r_sorted

and merge (i : int) (path : string list)
          (percentage : bool)
          (numeric : bool)
          (l : (string * json_withdiff) list)
          (r : (string * json_withdiff) list)
          : (string * json_withdiff) list =
  match (l, r) with
    | ([], rest) -> List.map (fun (s, j) -> (s, Diff (None, (Some j)))) rest
    | (rest, []) -> List.map (fun (s, j) -> (s, Diff ((Some j), None))) rest
    | ((s1, j1) :: l, (s2, j2) :: r) ->
        if s1 = s2 then
          (s1, diff (s1 :: path) percentage numeric j1 j2) :: (merge (i+1) path percentage numeric l r)
        else if s1 < s2 then
          (s1, Diff ((Some j1), None))
                :: (merge (i+1) path percentage numeric l ((s2, j2) :: r))
        else (* s1 > s2 *)
          (s2, Diff (None, (Some j2))) :: (merge (i+1) path percentage numeric ((s1, j1) :: l) r)

and diff (path : string list)
         (percentage : bool)
         (numeric : bool)
         (l : json_withdiff)
         (r : json_withdiff)
         : json_withdiff =
  match (l, r) with
    | (Null, Null) -> Null
    | (Bool b1, Bool b2) ->
        if b1 = b2 then Bool b1 else Diff (Some (Bool b1), Some (Bool b2))
    | (Int x, Int y) ->
        if x = y then
          Int x
        else
          if numeric then
            DiffNumeric (y - x)
          else if percentage then
            let x_as_float = float_of_int x
            in DiffPercentage
                 (round
                    ((((float_of_int y) -. x_as_float) /. x_as_float) *. 100.))
          else
            Diff (Some (Int x), Some (Int y))
    | (Intlit s1, Intlit s2) ->
        if s1 = s2 then
          Intlit s1
        else
          Diff (Some (Intlit s1), Some (Intlit s2))
    | (Float x, Float y) ->
        if x = y then
          Float x
        else
          Diff (Some (Float x), Some (Float y))
    | (String x, String y) ->
        if x = y then
          String x
        else
          Diff (Some (String x), Some (String y))
    | (List x, List y) when x = y ->
      List x
    | (List x, List y) when List.length x = List.length y ->
      List (map2i path (fun i a b -> diff (i2s i :: path) percentage numeric a b) x y)
    | (List x, List y) ->
      let xy =
        SD.get_diff (Array.of_list x) (Array.of_list y)
        |> List.concat_map (fun d ->
          match d with
          | SD.Equal e -> Array.to_list e
          | SD.Deleted e -> e |> Array.to_list
            |> List.map (fun e -> Diff (Some e, None))
          | SD.Added e -> e |> Array.to_list
            |> List.map (fun e -> Diff (None, Some e))
          )
      in List xy
    | (Tuple x, Tuple y) ->
        if x = y then Tuple x else Tuple (map2i path (fun i a b -> diff (i2s i :: path) percentage numeric a b) x y)
    | (Assoc x, Assoc y) ->
        if x = y then Assoc x else Assoc (diff_assoc path percentage numeric x y)
    | (Variant (t1, j1), Variant (t2, j2)) ->
        if t1 = t2 then
          (if j1 = j2 then
            Variant (t1,j1)
          else
            (match (j1, j2) with
              | (None, Some j2) ->
                  Variant (t1, Some (Diff (None, Some j2)))
              | (Some j1, None) ->
                  Variant (t1, Some (Diff (Some j1, None)))
              | (Some j1, Some j2) ->
                  Variant (t1, Some (Diff (Some j1, Some j2)))
              | (None, None) -> failwith "Impossible in diff"))
        else
          Diff (Some (Variant (t1, j1)), Some (Variant (t2, j2)))
    | (x, y) -> Diff (Some x, Some y)

let rec coerce : Y.Safe.t -> json_withdiff = function
  | `Assoc sjs -> Assoc (List.map (fun (s, j) -> (s, coerce j)) sjs)
  | `Bool b -> Bool b
  | `Float f -> Float f
  | `Int n -> Int n
  | `Intlit il -> Intlit il
  | `List xs -> List (List.map coerce xs)
  | `Null -> Null
  | `String s -> String s
  | `Tuple xs -> Tuple (List.map coerce xs)
  | `Variant (s, jo) -> Variant (s, option_map coerce jo)

(** Remove unchanged subtrees. The meaning of a diff changes from a
    snapshot of both states to something like a patch. *)
let rec filter_diff json =
  match json with
  | Null
  | Bool _
  | Int _
  | Intlit _
  | Float _
  | String _ -> json, false
  | Diff _
  | DiffNumeric _
  | DiffPercentage _ -> json, true
  | Assoc kvs ->
    let res = List.filter_map (fun (k, v) ->
      let v1, c = filter_diff v in
      if c then Some ((k, v1), c) else None) kvs
    in
    let changed = List.exists snd res in
    let res = Assoc (List.map fst res) in
    res, changed
  | List js ->
    (* lists are different from objects: ordering matters so unchanged
       elements are required to indicate what has changed. we keep them
       and just propagate an indication of whether a subtree has changed. *)
    let changed = List.exists (fun j -> filter_diff j |> snd) js in
    json, changed
  | Tuple _ -> failwith "Tuple"
  | Variant _ -> failwith "Variant"

let diff_strings (diff_only : bool)
                 (percentage : bool)
                 (numeric : bool)
                 (color : bool)
                 (l : string)
                 (r : string)
                 : string option =
  let l_json = coerce (Y.Safe.from_string l) in
  let r_json = coerce (Y.Safe.from_string r) in
  let diff = diff [] percentage numeric l_json r_json in
  let diff = if diff_only then fst @@ filter_diff diff else diff in
  if l_json = diff then
      None
     else
      Some (to_string ~color:color diff)

let bracket (acquire : unit -> 'a) (release : 'a -> 'b)
            (action : 'a -> 'c) : 'c =
  let h = acquire ()
  in try let result = action h
         in ignore (release h);
            result
     with e -> (ignore (release h); raise e)

let with_open_file (in_file : string) (action : in_channel -> 'a) : 'a =
    bracket (fun () -> open_in in_file) close_in action

let channel_get_lines (channel : in_channel) : string list =
  let rec get_lines_acc (return : string list -> string list)
                        (channel : in_channel)
                        : string list =
    let x = try Some (input_line channel) with End_of_file -> None
    in match x with
        | None -> return []
        | Some h -> get_lines_acc (fun result -> return (h :: result)) channel
  in get_lines_acc id channel

let _get_lines (file : string) : string list =
  with_open_file file channel_get_lines

let get_all (file : string) : string =
  with_open_file file (fun ic -> really_input_string ic (in_channel_length ic))

let print_diff : string option -> unit = function
  | None -> ()
  | Some s -> print_endline s

let () =
  let files = ref [] in
  let color = ref false in
  let numeric = ref false in
  let percentage = ref false in
  let diff_only = ref false in
  let options = [ ("-diff-only", Arg.Set diff_only, "Show only changes");
                  ("-color", Arg.Set color, "Always color output");
                  ("-numeric", Arg.Set numeric, "Compare numeric values numerically");
                  ("-percentage", Arg.Set percentage,
                    "Print numeric values percentage difference") ] in
  let msg = "JSON sensitive diff of two files" in
  Arg.parse options (fun file -> files := !files @ [file]) msg;
  if !numeric && !percentage then
    (prerr_endline "options -numeric and -percentage are incompatible";
     exit 1)
  else
    match (!color, !files) with
      | (color, [left; right]) ->
          let l = get_all left in
          let r = get_all right in
          let diff =
            try
              diff_strings !diff_only !percentage !numeric
                (if color then true else Unix.isatty Unix.stdout) l r
            with Invalid_argument s ->
              failwith s
          in
          print_diff diff
      | _ -> Arg.usage options msg

(*let test : unit =
  let t1 = diff (String "hello") (String "world") in
  let t1_result = Diff (Some (String "hello"), Some (String "world")) in
  let t2 = diff (String "hello") (String "") in
  let t2_result = Diff (Some (String "hello"), Some (String "")) in
  let t3 = diff (String "hello") (String "hello") in
  let t3_result = String "hello" in
  let t4 = diff (Variant ("Nil", None)) (Variant ("Nil", None)) in
  let t4_result = Variant ("Nil", None) in
  let t5 = diff (Variant ("Nil", Some (Int 42))) (Variant ("Nil", None)) in
  let t5_result = Variant ("Nil", Some (Diff (Some (Int 42), None))) in
  let t6 = diff (Variant ("Nil", Some (Int 42)))
                (Variant ("Nil", Some (String "foo"))) in
  let t6_result = Variant ("Nil", Some (Diff (Some (Int 42),
                                              Some (String "foo")))) in
  print_endline (to_string t1);
  assert (t1 = t1_result);
  print_endline (to_string t2);
  assert (t2 = t2_result);
  print_endline (to_string t3);
  assert (t3 = t3_result);
  print_endline (to_string t4);
  assert (t4 = t4_result);
  print_endline (to_string t5);
  assert (t5 = t5_result);
  print_endline (to_string t6);
  assert (t6 = t6_result)*)

(*let () = test*)
