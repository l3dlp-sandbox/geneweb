(* $Id: dag2html.ml,v 5.0 2005-12-13 11:51:26 ddr Exp $ *)

type 'a dag = { mutable dag : 'a node array }
and 'a node = { mutable pare : idag list; valu : 'a; mutable chil : idag list }
and idag

external int_of_idag : idag -> int = "%identity"
external idag_of_int : int -> idag = "%identity"

type 'a table = { mutable table : 'a data array array }
and 'a data = { mutable elem : 'a elem; mutable span : span_id }
and 'a elem = Elem of 'a | Ghost of ghost_id | Nothing
and span_id
and ghost_id

external span_id_of_int : int -> span_id = "%identity"
external ghost_id_of_int : int -> ghost_id = "%identity"

let new_span_id =
  let i = ref 0 in
  fun () ->
    incr i;
    span_id_of_int !i

let new_ghost_id =
  let i = ref 0 in
  fun () ->
    incr i;
    ghost_id_of_int !i

(* creating the html table structure *)

type align = LeftA | CenterA | RightA

type 'a table_data =
  | TDitem of Geneweb_db.Driver.iper * 'a * Adef.safe_string
  | TDtext of Geneweb_db.Driver.iper * Adef.safe_string
  | TDhr of align
  | TDbar of Adef.escaped_string option
  | TDnothing

type 'a html_table_line = (int * align * 'a table_data) array
type 'a html_table = 'a html_table_line array

let html_table_struct indi_ip indi_txt vbar_txt phony d t =
  let phony = function
    | Elem e -> phony d.dag.(int_of_idag e)
    | Ghost _ -> false
    | Nothing -> true
  in
  let elem_txt = function
    | Elem e ->
        TDitem
          ( indi_ip d.dag.(int_of_idag e),
            indi_txt d.dag.(int_of_idag e),
            Adef.safe "" )
    | Ghost _ -> TDbar None
    | Nothing -> TDnothing
  in
  let bar_txt first_vbar = function
    | Elem e ->
        let b =
          if first_vbar then Some (vbar_txt d.dag.(int_of_idag e)) else None
        in
        TDbar b
    | Ghost _ -> TDbar None
    | Nothing -> TDnothing
  in
  let all_empty i =
    let rec loop j =
      if j = Array.length t.table.(i) then true
      else
        match t.table.(i).(j).elem with
        | Nothing -> loop (j + 1)
        | (Elem _ | Ghost _) as e -> if phony e then loop (j + 1) else false
    in
    loop 0
  in
  let line_elem_txt i =
    let les =
      let rec loop les j =
        if j = Array.length t.table.(i) then les
        else
          let x = t.table.(i).(j) in
          let next_j =
            let rec loop j =
              if j = Array.length t.table.(i) then j
              else if t.table.(i).(j) = x then loop (j + 1)
              else j
            in
            loop (j + 1)
          in
          let colspan = 3 * (next_j - j) in
          let les = (1, LeftA, TDnothing) :: les in
          let les =
            let td =
              if t.table.(i).(j).elem = Nothing then TDnothing
              else elem_txt t.table.(i).(j).elem
            in
            (colspan - 2, CenterA, td) :: les
          in
          let les = (1, LeftA, TDnothing) :: les in
          loop les next_j
      in
      loop [] 0
    in
    Array.of_list (List.rev les)
  in
  let vbars_txt k i =
    let les =
      let rec loop les j =
        if j = Array.length t.table.(i) then les
        else
          let x = t.table.(i).(j) in
          let next_j =
            let rec loop j =
              if j = Array.length t.table.(i) then j
              else if t.table.(i).(j) = x then loop (j + 1)
              else j
            in
            loop (j + 1)
          in
          let colspan = 3 * (next_j - j) in
          let les = (1, LeftA, TDnothing) :: les in
          let les =
            let td =
              if
                (k > 0 && t.table.(k - 1).(j).elem = Nothing)
                || t.table.(k).(j).elem = Nothing
              then TDnothing
              else if phony t.table.(i).(j).elem then TDnothing
              else bar_txt (k <> i) t.table.(i).(j).elem
            in
            (colspan - 2, CenterA, td) :: les
          in
          let les = (1, LeftA, TDnothing) :: les in
          loop les next_j
      in
      loop [] 0
    in
    Array.of_list (List.rev les)
  in
  let alone_bar_txt i =
    let les =
      let rec loop les j =
        if j = Array.length t.table.(i) then les
        else
          let next_j =
            let x = t.table.(i).(j).span in
            let rec loop j =
              if j = Array.length t.table.(i) then j
              else if t.table.(i).(j).span = x then loop (j + 1)
              else j
            in
            loop (j + 1)
          in
          let colspan = (3 * (next_j - j)) - 2 in
          let les = (1, LeftA, TDnothing) :: les in
          let les =
            if
              t.table.(i).(j).elem = Nothing
              || t.table.(i + 1).(j).elem = Nothing
            then (colspan, LeftA, TDnothing) :: les
            else
              let td =
                let all_ph =
                  let rec loop j =
                    if j = next_j then true
                    else if phony t.table.(i + 1).(j).elem then loop (j + 1)
                    else false
                  in
                  loop j
                in
                if all_ph then TDnothing else TDbar None
              in
              (colspan, CenterA, td) :: les
          in
          let les = (1, LeftA, TDnothing) :: les in
          loop les next_j
      in
      loop [] 0
    in
    Array.of_list (List.rev les)
  in
  let exist_several_branches i k =
    let rec loop j =
      if j = Array.length t.table.(i) then false
      else
        let x = t.table.(i).(j).span in
        let e = t.table.(k).(j).elem in
        let rec loop1 j =
          if j = Array.length t.table.(i) then false
          else if t.table.(i).(j).elem = Nothing then loop j
          else if t.table.(i).(j).span <> x then loop j
          else if t.table.(k).(j).elem <> e then true
          else loop1 (j + 1)
        in
        loop1 (j + 1)
    in
    loop 0
  in
  let hbars_txt i k =
    let les =
      let rec loop les j =
        if j = Array.length t.table.(i) then les
        else
          let next_j =
            let e = t.table.(i).(j).elem in
            let x = t.table.(i).(j).span in
            let rec loop j =
              if j = Array.length t.table.(i) then j
              else if e = Nothing && t.table.(i).(j).elem = Nothing then
                loop (j + 1)
              else if t.table.(i).(j).span = x then loop (j + 1)
              else j
            in
            loop (j + 1)
          in
          let rec loop1 les l =
            if l = next_j then loop les next_j
            else
              let next_l =
                let y = t.table.(k).(l) in
                match y.elem with
                | Elem _ | Ghost _ ->
                    let rec loop l =
                      if l = Array.length t.table.(i) then l
                      else if t.table.(k).(l) = y then loop (l + 1)
                      else l
                    in
                    loop (l + 1)
                | Nothing -> l + 1
              in
              if next_l > next_j then (
                Printf.eprintf
                  "assert false i %d k %d l %d next_l %d next_j %d\n" i k l
                  next_l next_j;
                flush stderr);
              let next_l = min next_l next_j in
              let colspan = (3 * (next_l - l)) - 2 in
              let les =
                match (t.table.(i).(l).elem, t.table.(i + 1).(l).elem) with
                | Nothing, _ | _, Nothing ->
                    (colspan + 2, LeftA, TDnothing) :: les
                | _ ->
                    let ph s =
                      if phony t.table.(k).(l).elem then TDnothing else s
                    in
                    if l = j && next_l = next_j then
                      (1, LeftA, TDnothing)
                      :: (colspan, CenterA, ph (TDbar None))
                      :: (1, LeftA, TDnothing) :: les
                    else if l = j then
                      (1, LeftA, ph (TDhr CenterA))
                      :: (colspan, RightA, ph (TDhr RightA))
                      :: (1, LeftA, TDnothing) :: les
                    else if next_l = next_j then
                      (1, LeftA, TDnothing)
                      :: (colspan, LeftA, ph (TDhr LeftA))
                      :: (1, LeftA, ph (TDhr CenterA))
                      :: les
                    else (colspan + 2, LeftA, ph (TDhr CenterA)) :: les
              in
              loop1 les next_l
          in
          loop1 les j
      in
      loop [] 0
    in
    Array.of_list (List.rev les)
  in
  let hts =
    let rec loop hts i =
      if i = Array.length t.table then hts
      else if i = Array.length t.table - 1 && all_empty i then hts
      else
        let hts = line_elem_txt i :: hts in
        let hts =
          if i < Array.length t.table - 1 then
            let hts = vbars_txt (i + 1) i :: hts in
            let hts =
              if exist_several_branches i i then
                alone_bar_txt i :: hbars_txt i i :: hts
              else hts
            in
            if
              exist_several_branches i (i + 1)
              && (i < Array.length t.table - 2 || not (all_empty (i + 1)))
            then vbars_txt (i + 1) (i + 1) :: hbars_txt i (i + 1) :: hts
            else hts
          else hts
        in
        loop hts (i + 1)
    in
    loop [] 0
  in
  Array.of_list (List.rev hts)

(* transforming dag into table *)

let ancestors d =
  let rec loop i =
    if i = Array.length d.dag then []
    else
      let n = d.dag.(i) in
      if n.pare = [] then idag_of_int i :: loop (i + 1) else loop (i + 1)
  in
  loop 0

let get_children d parents =
  let merge_children children el =
    List.fold_right
      (fun (x, _) children ->
        match x with
        | Elem e ->
            let e = d.dag.(int_of_idag e) in
            List.fold_right
              (fun c children ->
                if List.mem c children then children else c :: children)
              e.chil children
        | Ghost _ | Nothing -> [])
      el children
  in
  merge_children [] parents

let rec get_block t i j =
  if j = Array.length t.table.(i) then None
  else if j = Array.length t.table.(i) - 1 then
    let x = t.table.(i).(j) in
    Some ([ (x.elem, 1) ], 1)
  else
    let x = t.table.(i).(j) in
    let y = t.table.(i).(j + 1) in
    if y.span = x.span then
      match get_block t i (j + 1) with
      | Some ((x1, c1) :: list, mpc) ->
          let list, mpc =
            if x1 = x.elem then ((x1, c1 + 1) :: list, max mpc (c1 + 1))
            else ((x.elem, 1) :: (x1, c1) :: list, max mpc c1)
          in
          Some (list, mpc)
      | _ -> assert false
    else Some ([ (x.elem, 1) ], 1)

let group_by_common_children d list =
  let module O = struct
    type t = idag

    let compare = compare
  end in
  let module S = Set.Make (O) in
  let nlcsl =
    List.map
      (fun id ->
        let n = d.dag.(int_of_idag id) in
        let cs = List.fold_right S.add n.chil S.empty in
        ([ id ], cs))
      list
  in
  let nlcsl =
    let rec loop = function
      | [] -> []
      | (nl, cs) :: rest ->
          let rec loop1 beg = function
            | (nl1, cs1) :: rest1 ->
                if S.is_empty (S.inter cs cs1) then
                  loop1 ((nl1, cs1) :: beg) rest1
                else
                  loop ((nl @ nl1, S.union cs cs1) :: List.rev_append beg rest1)
            | [] -> (nl, cs) :: loop rest
          in
          loop1 [] rest
    in
    loop nlcsl
  in
  List.fold_right
    (fun (nl, _) a ->
      let span = new_span_id () in
      List.fold_right (fun n a -> { elem = Elem n; span } :: a) nl a)
    nlcsl []

let copy_data d = { elem = d.elem; span = d.span }

let insert_columns t nb j =
  let t1 = Array.make (Array.length t.table) [||] in
  for i = 0 to Array.length t.table - 1 do
    let line = t.table.(i) in
    let line1 = Array.make (Array.length line + nb) line.(0) in
    t1.(i) <- line1;
    let rec loop k =
      if k = Array.length line then ()
      else (
        if k < j then line1.(k) <- copy_data line.(k)
        else if k = j then
          for r = 0 to nb do
            line1.(k + r) <- copy_data line.(k)
          done
        else line1.(k + nb) <- copy_data line.(k);
        loop (k + 1))
    in
    loop 0
  done;
  { table = t1 }

let rec gcd a b = if a < b then gcd b a else if b = 0 then a else gcd b (a mod b)

let treat_new_row d t =
  let i = Array.length t.table - 1 in
  let rec loop t i j =
    match get_block t i j with
    | Some (parents, max_parent_colspan) ->
        let children = get_children d parents in
        let children =
          if children = [] then [ { elem = Nothing; span = new_span_id () } ]
          else
            List.map
              (fun n -> { elem = Elem n; span = new_span_id () })
              children
        in
        let simple_parents_colspan =
          List.fold_left (fun x (_, c) -> x + c) 0 parents
        in
        if simple_parents_colspan mod List.length children = 0 then
          let j = j + simple_parents_colspan in
          let children =
            let cnt = simple_parents_colspan / List.length children in
            List.fold_right
              (fun d list ->
                let rec loop cnt list =
                  if cnt = 1 then d :: list
                  else copy_data d :: loop (cnt - 1) list
                in
                loop cnt list)
              children []
          in
          let t, children_rest = loop t i j in
          (t, children @ children_rest)
        else
          let parent_colspan =
            List.fold_left
              (fun scm (_, c) ->
                let g = gcd scm c in
                scm / g * c)
              max_parent_colspan parents
          in
          let t, parents, _ =
            List.fold_left
              (fun (t, parents, j) (x, c) ->
                let to_add = (parent_colspan / c) - 1 in
                let t =
                  let rec loop cc t j =
                    if cc = 0 then t
                    else
                      let t = insert_columns t to_add j in
                      loop (cc - 1) t (j + to_add + 1)
                  in
                  loop c t j
                in
                (t, (x, parent_colspan) :: parents, j + parent_colspan))
              (t, [], j) parents
          in
          let parents = List.rev parents in
          let parents_colspan = parent_colspan * List.length parents in
          let children_colspan = List.length children in
          let g = gcd parents_colspan children_colspan in
          let t, j =
            let cnt = children_colspan / g in
            List.fold_left
              (fun (t, j) (_, c) ->
                let rec loop cc t j =
                  if cc = 0 then (t, j)
                  else
                    let t = insert_columns t (cnt - 1) j in
                    let j = j + cnt in
                    loop (cc - 1) t j
                in
                loop c t j)
              (t, j) parents
          in
          let children =
            let cnt = parents_colspan / g in
            List.fold_right
              (fun d list ->
                let rec loop cnt list =
                  if cnt = 0 then list else d :: loop (cnt - 1) list
                in
                loop cnt list)
              children []
          in
          let t, children_rest = loop t i j in
          (t, children @ children_rest)
    | None -> (t, [])
  in
  loop t i 0

let down_it t i k =
  t.table.(Array.length t.table - 1).(k) <- t.table.(i).(k);
  for r = i to Array.length t.table - 2 do
    t.table.(r).(k) <- { elem = Ghost (new_ghost_id ()); span = new_span_id () }
  done

(* equilibrate:
   in the last line, for all elem A, make fall all As, which are located at
   its right side above, to its line,
                             A             |
   i.e. transform all        . into        |
                      A.......      A......A
*)

let equilibrate t =
  let ilast = Array.length t.table - 1 in
  let last = t.table.(ilast) in
  let len = Array.length last in
  let rec loop j =
    if j = len then ()
    else
      match last.(j).elem with
      | Elem x ->
          let rec loop1 i =
            if i = ilast then loop (j + 1)
            else
              let rec loop2 k =
                if k = len then loop1 (i + 1)
                else
                  match t.table.(i).(k).elem with
                  | Elem y when x = y ->
                      down_it t i k;
                      loop 0
                  | _ -> loop2 (k + 1)
              in
              loop2 0
          in
          loop1 0
      | Ghost _ | Nothing -> loop (j + 1)
  in
  loop 0

(* group_elem:
   transform all x y into x x
                 A A      A A *)

let group_elem t =
  for i = 0 to Array.length t.table - 2 do
    for j = 1 to Array.length t.table.(0) - 1 do
      match (t.table.(i + 1).(j - 1).elem, t.table.(i + 1).(j).elem) with
      | Elem x, Elem y when x = y ->
          t.table.(i).(j).span <- t.table.(i).(j - 1).span
      | _ -> ()
    done
  done

(* group_ghost:
                 x  x       x  x           |a |a      |a |a
   transform all |a |b into |a |a and all  x  y  into x  x
                 y  z       y  y           A  A       A  A *)

let group_ghost t =
  for i = 0 to Array.length t.table - 2 do
    for j = 1 to Array.length t.table.(0) - 1 do
      (match (t.table.(i + 1).(j - 1).elem, t.table.(i + 1).(j).elem) with
      | Ghost x, Ghost _ ->
          if t.table.(i).(j - 1).span = t.table.(i).(j).span then
            t.table.(i + 1).(j) <-
              { elem = Ghost x; span = t.table.(i + 1).(j - 1).span }
      | _ -> ());
      match (t.table.(i).(j - 1).elem, t.table.(i).(j).elem) with
      | Ghost x, Ghost _ ->
          if t.table.(i + 1).(j - 1).elem = t.table.(i + 1).(j).elem then (
            t.table.(i).(j) <-
              { elem = Ghost x; span = t.table.(i).(j - 1).span };
            if i > 0 then
              t.table.(i - 1).(j).span <- t.table.(i - 1).(j - 1).span)
      | _ -> ()
    done
  done

(* group_children:
   transform all A A into A A
                 x y      x x *)

let group_children t =
  for i = 0 to Array.length t.table - 1 do
    let line = t.table.(i) in
    let len = Array.length line in
    for j = 1 to len - 1 do
      if line.(j).elem = line.(j - 1).elem && line.(j).elem <> Nothing then
        line.(j).span <- line.(j - 1).span
    done
  done

(* group_span_by_common_children:
   in the last line, transform all
     A B into A B
     x y      x x
   if A and B have common children *)

let group_span_by_common_children d t =
  let module O = struct
    type t = idag

    let compare = compare
  end in
  let module S = Set.Make (O) in
  let i = Array.length t.table - 1 in
  let line = t.table.(i) in
  let rec loop j cs =
    if j = Array.length line then ()
    else
      match line.(j).elem with
      | Elem id ->
          let n = d.dag.(int_of_idag id) in
          let curr_cs = List.fold_right S.add n.chil S.empty in
          if S.is_empty (S.inter cs curr_cs) then loop (j + 1) curr_cs
          else (
            line.(j).span <- line.(j - 1).span;
            loop (j + 1) (S.union cs curr_cs))
      | Ghost _ | Nothing -> loop (j + 1) S.empty
  in
  loop 0 S.empty

let find_same_parents t i j1 j2 j3 j4 =
  let rec loop i j1 j2 j3 j4 =
    if i = 0 then (i, j1, j2, j3, j4)
    else
      let x1 = t.(i - 1).(j1) in
      let x2 = t.(i - 1).(j2) in
      let x3 = t.(i - 1).(j3) in
      let x4 = t.(i - 1).(j4) in
      if x1.span = x4.span then (i, j1, j2, j3, j4)
      else
        let j1 =
          let rec loop j =
            if j < 0 then 0
            else if t.(i - 1).(j).span = x1.span then loop (j - 1)
            else j + 1
          in
          loop (j1 - 1)
        in
        let j2 =
          let rec loop j =
            if j >= Array.length t.(i) then j - 1
            else if t.(i - 1).(j).span = x2.span then loop (j + 1)
            else j - 1
          in
          loop (j2 + 1)
        in
        let j3 =
          let rec loop j =
            if j < 0 then 0
            else if t.(i - 1).(j).span = x3.span then loop (j - 1)
            else j + 1
          in
          loop (j3 - 1)
        in
        let j4 =
          let rec loop j =
            if j >= Array.length t.(i) then j - 1
            else if t.(i - 1).(j).span = x4.span then loop (j + 1)
            else j - 1
          in
          loop (j4 + 1)
        in
        loop (i - 1) j1 j2 j3 j4
  in
  loop i j1 j2 j3 j4

let find_linked_children t i j1 j2 j3 j4 =
  let rec loop i j1 j2 j3 j4 =
    if i = Array.length t - 1 then (j1, j2, j3, j4)
    else
      let x1 = t.(i).(j1) in
      let x2 = t.(i).(j2) in
      let x3 = t.(i).(j3) in
      let x4 = t.(i).(j4) in
      let j1 =
        let rec loop j =
          if j < 0 then 0
          else if t.(i).(j).span = x1.span then loop (j - 1)
          else j + 1
        in
        loop (j1 - 1)
      in
      let j2 =
        let rec loop j =
          if j >= Array.length t.(i) then j - 1
          else if t.(i).(j).span = x2.span then loop (j + 1)
          else j - 1
        in
        loop (j2 + 1)
      in
      let j3 =
        let rec loop j =
          if j < 0 then 0
          else if t.(i).(j).span = x3.span then loop (j - 1)
          else j + 1
        in
        loop (j3 - 1)
      in
      let j4 =
        let rec loop j =
          if j >= Array.length t.(i) then j - 1
          else if t.(i).(j).span = x4.span then loop (j + 1)
          else j - 1
        in
        loop (j4 + 1)
      in
      loop (i + 1) j1 j2 j3 j4
  in
  loop i j1 j2 j3 j4

let mirror_block t i1 i2 j1 j2 =
  for i = i1 to i2 do
    let line = t.(i) in
    let rec loop j1 j2 =
      if j1 >= j2 then ()
      else
        let v = line.(j1) in
        line.(j1) <- line.(j2);
        line.(j2) <- v;
        loop (j1 + 1) (j2 - 1)
    in
    loop j1 j2
  done

let exch_blocks t i1 i2 j1 j2 j3 j4 =
  for i = i1 to i2 do
    let line = t.(i) in
    let saved = Array.copy line in
    for j = j1 to j2 do
      line.(j4 - j2 + j) <- saved.(j)
    done;
    for j = j3 to j4 do
      line.(j1 - j3 + j) <- saved.(j)
    done
  done

let find_block_with_parents t i jj1 jj2 jj3 jj4 =
  let rec loop ii jj1 jj2 jj3 jj4 =
    let nii, njj1, njj2, njj3, njj4 = find_same_parents t i jj1 jj2 jj3 jj4 in
    if nii <> ii || njj1 <> jj1 || njj2 <> jj2 || njj3 <> jj3 || njj4 <> jj4
    then
      let nii = min ii nii in
      let jj1, jj2, jj3, jj4 = find_linked_children t nii njj1 njj2 njj3 njj4 in
      if njj1 <> jj1 || njj2 <> jj2 || njj3 <> jj3 || njj4 <> jj4 then
        loop nii jj1 jj2 jj3 jj4
      else (nii, jj1, jj2, jj3, jj4)
    else (ii, jj1, jj2, jj3, jj4)
  in
  loop i jj1 jj2 jj3 jj4

let push_to_right t i j1 j2 =
  let line = t.(i) in
  let rec loop j =
    if j = j2 then j - 1
    else
      let ini_jj1 =
        match line.(j - 1).elem with
        | Nothing -> j - 1
        | x ->
            let rec same_value j =
              if j < 0 then 0
              else if line.(j).elem = x then same_value (j - 1)
              else j + 1
            in
            same_value (j - 2)
      in
      let jj1 = ini_jj1 in
      let jj2 = j - 1 in
      let jj3 = j in
      let jj4 =
        match line.(j).elem with
        | Nothing -> j
        | x ->
            let rec same_value j =
              if j >= Array.length line then j - 1
              else if line.(j).elem = x then same_value (j + 1)
              else j - 1
            in
            same_value (j + 1)
      in
      let ii, jj1, jj2, jj3, jj4 =
        find_block_with_parents t i jj1 jj2 jj3 jj4
      in
      if jj4 < j2 && jj2 < jj3 then (
        exch_blocks t ii i jj1 jj2 jj3 jj4;
        loop (jj4 + 1))
      else if jj4 < j2 && jj1 = ini_jj1 && jj2 <= jj4 then (
        mirror_block t ii i jj1 jj4;
        loop (jj4 + 1))
      else j - 1
  in
  loop (j1 + 1)

let push_to_left t i j1 j2 =
  let line = t.(i) in
  let rec loop j =
    if j = j1 then j + 1
    else
      let jj1 =
        match line.(j).elem with
        | Nothing -> j
        | x ->
            let rec same_value j =
              if j < 0 then 0
              else if line.(j).elem = x then same_value (j - 1)
              else j + 1
            in
            same_value (j - 1)
      in
      let jj2 = j in
      let jj3 = j + 1 in
      let ini_jj4 =
        match line.(j + 1).elem with
        | Nothing -> j + 1
        | x ->
            let rec same_value j =
              if j >= Array.length line then j - 1
              else if line.(j).elem = x then same_value (j + 1)
              else j - 1
            in
            same_value (j + 2)
      in
      let jj4 = ini_jj4 in
      let ii, jj1, jj2, jj3, jj4 =
        find_block_with_parents t i jj1 jj2 jj3 jj4
      in
      if jj1 > j1 && jj2 < jj3 then (
        exch_blocks t ii i jj1 jj2 jj3 jj4;
        loop (jj1 - 1))
      else if jj1 > j1 && jj4 = ini_jj4 && jj3 >= jj1 then (
        mirror_block t ii i jj1 jj4;
        loop (jj1 - 1))
      else j + 1
  in
  loop (j2 - 1)

let fill_gap t i j1 j2 =
  let t1 =
    let t1 = Array.copy t.table in
    for i = 0 to Array.length t.table - 1 do
      t1.(i) <- Array.copy t.table.(i);
      for j = 0 to Array.length t1.(i) - 1 do
        t1.(i).(j) <- copy_data t.table.(i).(j)
      done
    done;
    t1
  in
  let j2 = push_to_left t1 i j1 j2 in
  let j1 = push_to_right t1 i j1 j2 in
  if j1 = j2 - 1 then (
    let line = t1.(i - 1) in
    let x = line.(j1).span in
    let y = line.(j2).span in
    let rec loop y j =
      if j >= Array.length line then ()
      else if line.(j).span = y || t1.(i).(j).elem = t1.(i).(j - 1).elem then (
        let y = line.(j).span in
        line.(j).span <- x;
        if i > 0 then t1.(i - 1).(j).span <- t1.(i - 1).(j - 1).span;
        loop y (j + 1))
      else loop line.(j).span (j + 1)
    in
    loop y j2;
    Some ({ table = t1 }, true))
  else None

let treat_gaps t =
  let i = Array.length t.table - 1 in
  let rec loop t j =
    let line = t.table.(i) in
    if j = Array.length line then t
    else
      match line.(j).elem with
      | Elem _ as y ->
          if y = line.(j - 1).elem then loop t (j + 1)
          else
            let rec loop1 t j1 =
              if j1 < 0 then loop t (j + 1)
              else if y = line.(j1).elem then
                match fill_gap t i j1 j with
                | Some (t, ok) -> if ok then loop t 2 else loop t (j + 1)
                | None -> loop t (j + 1)
              else loop1 t (j1 - 1)
            in
            loop1 t (j - 2)
      | _ -> loop t (j + 1)
  in
  if Array.length t.table.(i) = 1 then t else loop t 2

let group_span_last_row t =
  let row = t.table.(Array.length t.table - 1) in
  let rec loop i =
    if i >= Array.length row then ()
    else (
      (match row.(i).elem with
      | (Elem _ | Ghost _) as x ->
          if x = row.(i - 1).elem then row.(i).span <- row.(i - 1).span
      | _ -> ());
      loop (i + 1))
  in
  loop 1

let has_phony_children phony d t =
  let line = t.table.(Array.length t.table - 1) in
  let rec loop j =
    if j = Array.length line then false
    else
      match line.(j).elem with
      | Elem x -> if phony d.dag.(int_of_idag x) then true else loop (j + 1)
      | _ -> loop (j + 1)
  in
  loop 0

let tablify phony no_optim no_group d =
  let a = ancestors d in
  let r = group_by_common_children d a in
  let t = { table = [| Array.of_list r |] } in
  let rec loop t =
    let t, new_row = treat_new_row d t in
    if List.for_all (fun x -> x.elem = Nothing) new_row then t
    else
      let t = { table = Array.append t.table [| Array.of_list new_row |] } in
      let t =
        if no_group && not (has_phony_children phony d t) then t
        else
          let _ = if no_optim then () else equilibrate t in
          let _ = group_elem t in
          let _ = group_ghost t in
          let _ = group_children t in
          let _ = group_span_by_common_children d t in
          let t = if no_optim then t else treat_gaps t in
          let _ = group_span_last_row t in
          t
      in
      loop t
  in
  loop t

let fall t =
  for i = 1 to Array.length t.table - 1 do
    let line = t.table.(i) in
    let rec loop j =
      if j = Array.length line then ()
      else
        match line.(j).elem with
        | Ghost x ->
            let j2 =
              let rec loop j =
                if j = Array.length line then j - 1
                else
                  match line.(j).elem with
                  | Ghost y when y = x -> loop (j + 1)
                  | _ -> j - 1
              in
              loop (j + 1)
            in
            let i1 =
              let rec loop i =
                if i < 0 then i + 1
                else
                  let line = t.table.(i) in
                  if
                    (j = 0 || line.(j - 1).span <> line.(j).span)
                    && (j2 = Array.length line - 1
                       || line.(j2 + 1).span <> line.(j2).span)
                  then loop (i - 1)
                  else i + 1
              in
              loop (i - 1)
            in
            let i1 =
              if i1 = i then i1
              else if i1 = 0 then i1
              else if t.table.(i1).(j).elem = Nothing then i1
              else i
            in
            if i1 < i then (
              for k = i downto i1 + 1 do
                for j = j to j2 do
                  t.table.(k).(j).elem <- t.table.(k - 1).(j).elem;
                  if k < i then t.table.(k).(j).span <- t.table.(k - 1).(j).span
                done
              done;
              for l = j to j2 do
                if i1 = 0 || t.table.(i1 - 1).(l).elem = Nothing then
                  t.table.(i1).(l).elem <- Nothing
                else
                  t.table.(i1).(l) <-
                    (if
                       l = j
                       || t.table.(i1 - 1).(l - 1).span
                          <> t.table.(i1 - 1).(l).span
                     then
                       { elem = Ghost (new_ghost_id ()); span = new_span_id () }
                     else copy_data t.table.(i1).(l - 1))
              done);
            loop (j2 + 1)
        | _ -> loop (j + 1)
    in
    loop 0
  done

let fall2_cool_right t i1 i2 j1 j2 =
  let span = t.table.(i2 - 1).(j1).span in
  for i = i2 - 1 downto 0 do
    for j = j1 to j2 - 1 do
      t.table.(i).(j) <-
        (if i - i2 + i1 >= 0 then t.table.(i - i2 + i1).(j)
         else { elem = Nothing; span = new_span_id () })
    done
  done;
  for i = Array.length t.table - 1 downto 0 do
    for j = j2 to Array.length t.table.(i) - 1 do
      t.table.(i).(j) <-
        (if i - i2 + i1 >= 0 then t.table.(i - i2 + i1).(j)
         else { elem = Nothing; span = new_span_id () })
    done
  done;
  let old_span = t.table.(i2 - 1).(j1).span in
  let rec loop j =
    if j = Array.length t.table.(i2 - 1) then ()
    else if t.table.(i2 - 1).(j).span = old_span then (
      t.table.(i2 - 1).(j).span <- span;
      loop (j + 1))
  in
  loop j1

let fall2_cool_left t i1 i2 j1 j2 =
  let span = t.table.(i2 - 1).(j2).span in
  for i = i2 - 1 downto 0 do
    for j = j1 + 1 to j2 do
      t.table.(i).(j) <-
        (if i - i2 + i1 >= 0 then t.table.(i - i2 + i1).(j)
         else { elem = Nothing; span = new_span_id () })
    done
  done;
  for i = Array.length t.table - 1 downto 0 do
    for j = j1 downto 0 do
      t.table.(i).(j) <-
        (if i - i2 + i1 >= 0 then t.table.(i - i2 + i1).(j)
         else { elem = Nothing; span = new_span_id () })
    done
  done;
  let old_span = t.table.(i2 - 1).(j2).span in
  let rec loop j =
    if j < 0 then ()
    else if t.table.(i2 - 1).(j).span = old_span then (
      t.table.(i2 - 1).(j).span <- span;
      loop (j - 1))
  in
  loop j2

let do_fall2_right t i1 i2 j1 j2 =
  let i3 =
    let rec loop_i i =
      if i < 0 then 0
      else
        let rec loop_j j =
          if j = Array.length t.table.(i) then loop_i (i - 1)
          else
            match t.table.(i).(j).elem with
            | Nothing -> loop_j (j + 1)
            | _ -> i + 1
        in
        loop_j j2
    in
    loop_i (Array.length t.table - 1)
  in
  let new_height = i3 + i2 - i1 in
  let t =
    if new_height > Array.length t.table then
      let rec loop cnt t =
        if cnt = 0 then t
        else
          let new_line =
            Array.init
              (Array.length t.table.(0))
              (fun _ -> { elem = Nothing; span = new_span_id () })
          in
          let t = { table = Array.append t.table [| new_line |] } in
          loop (cnt - 1) t
      in
      loop (new_height - Array.length t.table) t
    else t
  in
  fall2_cool_right t i1 i2 j1 j2;
  t

let do_fall2_left t i1 i2 j1 j2 =
  let i3 =
    let rec loop_i i =
      if i < 0 then 0
      else
        let rec loop_j j =
          if j < 0 then loop_i (i - 1)
          else
            match t.table.(i).(j).elem with
            | Nothing -> loop_j (j - 1)
            | _ -> i + 1
        in
        loop_j j1
    in
    loop_i (Array.length t.table - 1)
  in
  let new_height = i3 + i2 - i1 in
  let t =
    if new_height > Array.length t.table then
      let rec loop cnt t =
        if cnt = 0 then t
        else
          let new_line =
            Array.init
              (Array.length t.table.(0))
              (fun _ -> { elem = Nothing; span = new_span_id () })
          in
          let t = { table = Array.append t.table [| new_line |] } in
          loop (cnt - 1) t
      in
      loop (new_height - Array.length t.table) t
    else t
  in
  fall2_cool_left t i1 i2 j1 j2;
  t

let do_shorten_too_long t i1 j1 j2 =
  for i = i1 to Array.length t.table - 2 do
    for j = j1 to j2 - 1 do
      t.table.(i).(j) <- t.table.(i + 1).(j)
    done
  done;
  let i = Array.length t.table - 1 in
  for j = j1 to j2 - 1 do
    t.table.(i).(j) <- { elem = Nothing; span = new_span_id () }
  done;
  t

let try_fall2_right t i j =
  match t.table.(i).(j).elem with
  | Ghost _ ->
      let i1 =
        let rec loop i =
          if i < 0 then 0
          else
            match t.table.(i).(j).elem with
            | Ghost _ -> loop (i - 1)
            | _ -> i + 1
        in
        loop (i - 1)
      in
      let separated1 =
        let rec loop i =
          if i < 0 then true
          else if j > 0 && t.table.(i).(j - 1).span = t.table.(i).(j).span then
            false
          else loop (i - 1)
        in
        loop (i1 - 1)
      in
      let j2 =
        let x = t.table.(i).(j).span in
        let rec loop j2 =
          if j2 = Array.length t.table.(i) then j2
          else
            match t.table.(i).(j2) with
            | { elem = Ghost _; span = y } when y = x -> loop (j2 + 1)
            | _ -> j2
        in
        loop (j + 1)
      in
      let separated2 =
        let rec loop i =
          if i = Array.length t.table then true
          else if j2 = Array.length t.table.(i) then false
          else if t.table.(i).(j2 - 1).span = t.table.(i).(j2).span then false
          else loop (i + 1)
        in
        loop (i + 1)
      in
      if (not separated1) || not separated2 then None
      else Some (do_fall2_right t i1 (i + 1) j j2)
  | _ -> None

let try_fall2_left t i j =
  match t.table.(i).(j).elem with
  | Ghost _ ->
      let i1 =
        let rec loop i =
          if i < 0 then 0
          else
            match t.table.(i).(j).elem with
            | Ghost _ -> loop (i - 1)
            | _ -> i + 1
        in
        loop (i - 1)
      in
      let separated1 =
        let rec loop i =
          if i < 0 then true
          else if
            j < Array.length t.table.(i) - 1
            && t.table.(i).(j).span = t.table.(i).(j + 1).span
          then false
          else loop (i - 1)
        in
        loop (i1 - 1)
      in
      let j1 =
        let x = t.table.(i).(j).span in
        let rec loop j1 =
          if j1 < 0 then j1
          else
            match t.table.(i).(j1) with
            | { elem = Ghost _; span = y } when y = x -> loop (j1 - 1)
            | _ -> j1
        in
        loop (j - 1)
      in
      let separated2 =
        let rec loop i =
          if i = Array.length t.table then true
          else if j1 < 0 then false
          else if t.table.(i).(j1).span = t.table.(i).(j1 + 1).span then false
          else loop (i + 1)
        in
        loop (i + 1)
      in
      if (not separated1) || not separated2 then None
      else Some (do_fall2_left t i1 (i + 1) j1 j)
  | _ -> None

let try_shorten_too_long t i j =
  match t.table.(i).(j).elem with
  | Ghost _ ->
      let j2 =
        let x = t.table.(i).(j).span in
        let rec loop j2 =
          if j2 = Array.length t.table.(i) then j2
          else
            match t.table.(i).(j2) with
            | { elem = Ghost _; span = y } when y = x -> loop (j2 + 1)
            | _ -> j2
        in
        loop (j + 1)
      in
      let i1 =
        let rec loop i =
          if i = Array.length t.table then i
          else match t.table.(i).(j).elem with Elem _ -> loop (i + 1) | _ -> i
        in
        loop (i + 1)
      in
      let i2 =
        let rec loop i =
          if i = Array.length t.table then i
          else
            match t.table.(i).(j).elem with Nothing -> loop (i + 1) | _ -> i
        in
        loop i1
      in
      let separated_left =
        let rec loop i =
          if i = i2 then true
          else if j > 0 && t.table.(i).(j).span = t.table.(i).(j - 1).span then
            false
          else loop (i + 1)
        in
        loop i
      in
      let separated_right =
        let rec loop i =
          if i = i2 then true
          else if
            j2 < Array.length t.table.(i)
            && t.table.(i).(j2 - 1).span = t.table.(i).(j2).span
          then false
          else loop (i + 1)
        in
        loop i
      in
      if (not separated_left) || not separated_right then None
      else if i2 < Array.length t.table then None
      else Some (do_shorten_too_long t i j j2)
  | _ -> None

let fall2_right t =
  let rec loop_i i t =
    if i <= 0 then t
    else
      let rec loop_j j t =
        if j < 0 then loop_i (i - 1) t
        else
          match try_fall2_right t i j with
          | Some t -> loop_i (Array.length t.table - 1) t
          | None -> loop_j (j - 1) t
      in
      loop_j (Array.length t.table.(i) - 2) t
  in
  loop_i (Array.length t.table - 1) t

let fall2_left t =
  let rec loop_i i t =
    if i <= 0 then t
    else
      let rec loop_j j t =
        if j >= Array.length t.table.(i) then loop_i (i - 1) t
        else
          match try_fall2_left t i j with
          | Some t -> loop_i (Array.length t.table - 1) t
          | None -> loop_j (j + 1) t
      in
      loop_j 1 t
  in
  loop_i (Array.length t.table - 1) t

let shorten_too_long t =
  let rec loop_i i t =
    if i <= 0 then t
    else
      let rec loop_j j t =
        if j >= Array.length t.table.(i) then loop_i (i - 1) t
        else
          match try_shorten_too_long t i j with
          | Some t -> loop_i (Array.length t.table - 1) t
          | None -> loop_j (j + 1) t
      in
      loop_j 1 t
  in
  loop_i (Array.length t.table - 1) t

(* top_adjust:
   deletes all empty rows that might have appeared on top of the table
   after the falls *)

let top_adjust t =
  let di =
    let rec loop i =
      if i = Array.length t.table then i
      else
        let rec loop_j j =
          if j = Array.length t.table.(i) then loop (i + 1)
          else if t.table.(i).(j).elem <> Nothing then i
          else loop_j (j + 1)
        in
        loop_j 0
    in
    loop 0
  in
  if di > 0 then (
    for i = 0 to Array.length t.table - 1 - di do
      t.table.(i) <- t.table.(i + di)
    done;
    { table = Array.sub t.table 0 (Array.length t.table - di) })
  else t

(* bottom_adjust:
   deletes all empty rows that might have appeared on bottom of the table
   after the falls *)

let bottom_adjust t =
  let last_i =
    let rec loop i =
      if i < 0 then i
      else
        let rec loop_j j =
          if j = Array.length t.table.(i) then loop (i - 1)
          else if t.table.(i).(j).elem <> Nothing then i
          else loop_j (j + 1)
        in
        loop_j 0
    in
    loop (Array.length t.table - 1)
  in
  if last_i < Array.length t.table - 1 then
    { table = Array.sub t.table 0 (last_i + 1) }
  else t

(* invert *)

let invert_dag d =
  let d = { dag = Array.copy d.dag } in
  for i = 0 to Array.length d.dag - 1 do
    let n = d.dag.(i) in
    d.dag.(i) <-
      {
        pare = List.map (fun x -> x) n.chil;
        valu = n.valu;
        chil = List.map (fun x -> x) n.pare;
      }
  done;
  d

let invert_table t =
  let t' = { table = Array.copy t.table } in
  let len = Array.length t.table in
  for i = 0 to len - 1 do
    t'.table.(i) <-
      Array.init
        (Array.length t.table.(0))
        (fun j ->
          let d = t.table.(len - 1 - i).(j) in
          { elem = d.elem; span = d.span });
    if i < len - 1 then
      for j = 0 to Array.length t'.table.(i) - 1 do
        t'.table.(i).(j).span <- t.table.(len - 2 - i).(j).span
      done
  done;
  t'

(* main *)

let table_of_dag phony no_optim invert no_group d =
  let d = if invert then invert_dag d else d in
  let t = tablify phony no_optim no_group d in
  let t = if invert then invert_table t else t in
  let _ = fall t in
  fall2_right t |> fall2_left |> shorten_too_long |> top_adjust |> bottom_adjust
