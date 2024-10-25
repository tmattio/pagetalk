type status = Pending | Approved | Rejected | Spam

let _string_of_status = function
  | Pending -> "pending"
  | Approved -> "approved"
  | Rejected -> "rejected"
  | Spam -> "spam"

let _status_of_string = function
  | "pending" -> Pending
  | "approved" -> Approved
  | "rejected" -> Rejected
  | "spam" -> Spam
  | _ -> Pending (* Default to pending for unknown status *)

type t = {
  id : string;
  page_url : string;
  author : string;
  email : string option;
  website : string option;
  content : string;
  timestamp : float;
  parent_id : string option;
  status : status;
  moderation_notes : string option;
  moderated_at : float option;
  moderated_by : string option;
}

let string_of_status = function
  | Pending -> "pending"
  | Approved -> "approved"
  | Rejected -> "rejected"
  | Spam -> "spam"

let status_of_string = function
  | "pending" -> Pending
  | "approved" -> Approved
  | "rejected" -> Rejected
  | "spam" -> Spam
  | _ -> Pending (* Default to pending for unknown status *)


let comments : (string, t) Hashtbl.t = Hashtbl.create 100

let generate_id () =
  Random.self_init ();
  Random.bits () |> string_of_int

let get_all_comments () =
  Hashtbl.fold (fun _ v acc -> v :: acc) comments []

let get_comment id = Hashtbl.find_opt comments id

let add_comment ~page_url ~author ~email ~website ~content ~parent_id =
  let id = generate_id () in
  let timestamp = Unix.time () in
  let status = Pending in
  let moderation_notes = None in
  let moderated_at = None in
  let moderated_by = None in
  let comment = { id; page_url; author; email; website; content; timestamp; parent_id; status; moderation_notes; moderated_at; moderated_by } in
  Hashtbl.add comments id comment;
  comment

let update_comment comment =
  Hashtbl.replace comments comment.id comment

let delete_comment id = Hashtbl.remove comments id

let page_comments url = List.filter (fun c -> c.page_url = url) (get_all_comments ())