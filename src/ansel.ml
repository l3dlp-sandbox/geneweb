(* $Id: ansel.ml,v 5.3 2007-01-19 01:53:16 ddr Exp $ *)
(* Copyright (c) 1998-2007 INRIA *)

value no_accent =
  fun
  [ '�' | '�' | '�' | '�' | '�' | '�' -> 'a'
  | '�' -> 'c'
  | '�' | '�' | '�' | '�' -> 'e'
  | '�' | '�' | '�' | '�' -> 'i'
  | '�' -> 'n'
  | '�' | '�' | '�' | '�' | '�' | '�' -> 'o'
  | '�' | '�' | '�' | '�' -> 'u'
  | '�' | '�' -> 'y'
  | '�' | '�' | '�' | '�' | '�' | '�' -> 'A'
  | '�' -> 'C'
  | '�' | '�' | '�' | '�' -> 'E'
  | '�' | '�' | '�' | '�' -> 'I'
  | '�' -> 'N'
  | '�' | '�' | '�' | '�' | '�' | '�' -> 'O'
  | '�' | '�' | '�' | '�' -> 'U'
  | '�' -> 'Y'
  | c -> c ]
;

value of_iso_8859_1 s =
  let (len, identical) =
    loop 0 0 True where rec loop i len identical =
      if i = String.length s then (len, identical)
      else
        match s.[i] with
        [ '�'..'�' | '�'.. '�' | '�'..'�' | '�'..'�'
        | '�'..'�' | '�'.. '�' | '�'..'�' | '�'..'�' | '�' ->
            loop (i + 1) (len + 2) False
        | '�' -> loop (i + 1) (len + 1) False
        | '�' -> loop (i + 1) (len + 1) False
        | '�' -> loop (i + 1) (len + 1) False
        | _ -> loop (i + 1) (len + 1) identical ]
  in
  if identical then s
  else
    let s' = Bytes.create len in
    loop 0 0 where rec loop i i' =
      if i = String.length s then s'
      else
        let i' =
          match s.[i] with
          [ '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 225); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' | '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 226); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 227); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' | '�' | '�' | '�' | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 228); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' | '�' | '�' | '�' | '�'
          | '�' | '�' | '�' | '�' | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 232); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 234); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' | '�' ->
              do {
                Bytes.set s' i' (Char.chr 240); Bytes.set s' (i'+1) (no_accent s.[i]);
                i' + 1
              }
          | '�' -> do { Bytes.set s' i' (Char.chr 162); i' }
          | '�' -> do { Bytes.set s' i' (Char.chr 178); i' }
          | '�' -> do { Bytes.set s' i' (Char.chr 207); i' }
          | c -> do { Bytes.set s' i' c; i' } ]
        in
        loop (i + 1) (i' + 1)
;

value grave =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | x -> x ]
;

value acute =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'y' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | 'Y' -> '�'
  | x -> x ]
;

value circum =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | x -> x ]
;

value uml =
  fun
  [ 'a' -> '�'
  | 'e' -> '�'
  | 'i' -> '�'
  | 'o' -> '�'
  | 'u' -> '�'
  | 'y' -> '�'
  | 'A' -> '�'
  | 'E' -> '�'
  | 'I' -> '�'
  | 'O' -> '�'
  | 'U' -> '�'
  | x -> x ]
;

value circle =
  fun
  [ 'a' -> '�'
  | 'A' -> '�'
  | x -> x ]
;

value tilde =
  fun
  [ 'a' -> '�'
  | 'n' -> '�'
  | 'o' -> '�'
  | 'A' -> '�'
  | 'N' -> '�'
  | 'O' -> '�'
  | x -> x ]
;

value cedil =
  fun
  [ 'c' -> '�'
  | 'C' -> '�'
  | x -> x ]
;

value to_iso_8859_1 s =
  let (len, identical) =
    loop 0 0 True where rec loop i len identical =
      if i = String.length s then (len, identical)
      else if i = String.length s - 1 then (len + 1, identical)
      else
        match Char.code s.[i] with
        [ 225 | 226 | 227 | 228 | 232 | 234 | 240 ->
            loop (i + 2) (len + 1) False
        | 162 -> loop (i + 1) (len + 1) False
        | 178 -> loop (i + 1) (len + 1) False
        | 207 -> loop (i + 1) (len + 1) False
        | _ -> loop (i + 1) (len + 1) identical]
  in
  if identical then s
  else
    let s' = Bytes.create len in
    loop 0 0 where rec loop i i' =
      if i = String.length s then s'
      else if i = String.length s - 1 then
        do { Bytes.set s' i' s.[i]; s' }
      else
        let i =
          match Char.code s.[i] with
          [ 162 -> do { Bytes.set s' i' '�'; i }
          | 178 -> do { Bytes.set s' i' '�'; i }
          | 207 -> do { Bytes.set s' i' '�'; i }
          | 225 -> do { Bytes.set s' i' (grave s.[i+1]); i + 1 }
          | 226 -> do { Bytes.set s' i' (acute s.[i+1]); i + 1 }
          | 227 -> do { Bytes.set s' i' (circum s.[i+1]); i + 1 }
          | 228 -> do { Bytes.set s' i' (tilde s.[i+1]); i + 1 }
          | 232 -> do { Bytes.set s' i' (uml s.[i+1]); i + 1 }
          | 234 -> do { Bytes.set s' i' (circle s.[i+1]); i + 1 }
          | 240 -> do { Bytes.set s' i' (cedil s.[i+1]); i + 1 }
          | _ -> do { Bytes.set s' i' s.[i]; i } ]
        in
        loop (i + 1) (i' + 1)
;
