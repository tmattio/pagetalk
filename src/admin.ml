(* Simple in-memory admin credentials - replace with proper auth system *)
let admin_credentials = [ ("admin", "secure_password") ]

let is_authenticated request =
  match Dream.session_field request "admin_authenticated" with
  | Some "true" -> true
  | _ -> false

let login_page_handler request =
  let csrf_token = Dream.csrf_token request in
  let error = Dream.query request "error" in
  Dream.html (Templates.Login.render ~error ~csrf_token)

let login_handler request =
  match%lwt Dream.form request with
  | `Ok [ ("password", password); ("username", username) ]
    when List.exists
           (fun (u, p) -> u = username && p = password)
           admin_credentials ->
      let%lwt () =
        Dream.set_session_field request "admin_authenticated" "true"
      in
      Dream.redirect request "/admin"
  | _ ->
    Dream.redirect request "/admin/login?error=1"

let admin_page_handler request =
  if not (is_authenticated request) then Dream.redirect request "/admin/login"
  else
    let all_comments = Comment.get_all_comments () in
    let pending_comments =
      List.filter (fun (c : Comment.t) -> c.status = Pending) all_comments
    in
    let approved_comments =
      List.filter (fun (c : Comment.t) -> c.status = Approved) all_comments
    in
    let rejected_comments =
      List.filter (fun (c : Comment.t) -> c.status = Rejected) all_comments
    in
    let spam_comments = List.filter (fun (c : Comment.t) -> c.status = Spam) all_comments in
    Dream.html (
        Templates.Admin.render ~comments:all_comments
          ~pending_count:(List.length pending_comments)
          ~approved_count:(List.length approved_comments)
          ~rejected_count:(List.length rejected_comments)
          ~spam_count:(List.length spam_comments)
          ~csrf_token:(Dream.csrf_token request)
          )

let moderate_handler request =
  if not (is_authenticated request) then Dream.redirect request "/admin/login"
  else
    match%lwt Dream.form request with
    | `Ok [ ("comment_id", id); ("status", status) ] -> (
        match Comment.get_comment id with
        | Some comment ->
            Comment.update_comment { comment with status = Comment.status_of_string status };
            Dream.redirect request "/admin"
        | None -> Dream.redirect request "/admin")
    | _ -> Dream.redirect request "/admin"

let bulk_moderate_handler request =
  if not (is_authenticated request) then
    Dream.redirect request "/admin/login"
  else
    match%lwt Dream.form request with
    | `Ok params ->
        (* params is already a (string * string) list *)
        let comment_ids = List.filter_map
          (function
            | ("comment_ids[]", id) -> Some id
            | _ -> None)
          params
        in
        let action = List.assoc_opt "bulk_action" params in
        let status = match action with
          | Some "approve" -> Some Comment.Approved
          | Some "reject" -> Some Rejected
          | Some "mark_spam" -> Some Spam
          | _ -> None
        in
        (match status with
        | Some new_status ->
            List.iter (fun id ->
              match Comment.get_comment id with
              | Some comment -> 
                  Comment.update_comment { comment with status = new_status }
              | None -> ())
              comment_ids;
            Dream.redirect request "/admin"
        | None ->
          Dream.redirect request "/admin")
    | _ ->
      Dream.redirect request "/admin"
    
let logout_handler request =
  let%lwt () = Dream.invalidate_session request in
  Dream.redirect request "/admin/login"

let routes =
  [
    Dream.get "/admin/login" login_page_handler;
    Dream.post "/admin/login" login_handler;
    Dream.get "/admin" admin_page_handler;
    Dream.post "/admin/moderate" moderate_handler;
    Dream.post "/admin/bulk-moderate" bulk_moderate_handler;
    Dream.post "/admin/logout" logout_handler;
  ]
