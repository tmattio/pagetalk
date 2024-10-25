(* CORS middleware *)
let cors_middleware =
  let cors_headers =
    [
      ("Access-Control-Allow-Origin", "*");
      ("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      ("Access-Control-Allow-Headers", "Content-Type");
      ("Access-Control-Max-Age", "3600");
    ]
  in
  fun handler request ->
    match Dream.method_ request with
    | `OPTIONS -> Dream.respond ~headers:cors_headers ""
    | _ ->
        let%lwt response = handler request in
        let headers =
          List.fold_left
            (fun acc (key, value) ->
              Dream.add_header acc key value;
              response)
            response cors_headers
        in
        Lwt.return headers

(* Convert comment to JSON *)
let comment_to_json comment =
  `Assoc
    [
      ("id", `String comment.Comment.id);
      ("pageUrl", `String comment.page_url);
      ("author", `String comment.author);
      ("email", match comment.email with Some e -> `String e | None -> `Null);
      ( "website",
        match comment.website with Some w -> `String w | None -> `Null );
      ("content", `String comment.content);
      ("timestamp", `Float comment.timestamp);
      ( "parentId",
        match comment.parent_id with Some id -> `String id | None -> `Null );
    ]

let serve_js_handler _request =
  Dream.respond
    ~headers:
      [
        ("Content-Type", "application/javascript");
        (* "Cache-Control", "public, max-age=3600"; (* Cache for 1 hour *) *)
      ]
    Asset.pagetalk_js

let serve_css_handler _request =
  Dream.respond ~headers:[ ("Content-Type", "text/css") ] Asset.pagetalk_css

(* Get comments for a specific page *)
let get_comments_handler request =
  match Dream.query request "pageUrl" with
  | None -> Dream.respond ~status:`Bad_Request "Missing pageUrl parameter"
  | Some page_url ->
      (* Filter and sort comments *)
      let page_comments =
        Comment.page_comments page_url
        |> List.filter (fun c -> c.Comment.status = Comment.Approved)
        |> List.sort (fun c1 c2 ->
               (* Sort by timestamp, newest first *)
               compare c2.Comment.timestamp c1.Comment.timestamp)
      in

      (* Build comment tree *)
      let rec build_tree comment =
        let children =
          List.filter
            (fun c ->
              match c.Comment.parent_id with
              | Some parent_id -> parent_id = comment.Comment.id
              | None -> false)
            page_comments
          |> List.map build_tree
        in
        let comment_json = comment_to_json comment in
        match children with
        | [] -> comment_json
        | _ ->
            `Assoc
              ((match comment_json with `Assoc fields -> fields | _ -> [])
              @ [ ("replies", `List children) ])
      in

      (* Get root level comments (no parent_id) *)
      let root_comments =
        List.filter (fun comment -> comment.Comment.parent_id = None) page_comments
        |> List.map build_tree
      in

      let response =
        `Assoc
          [
            ("comments", `List root_comments);
            ("total", `Int (List.length page_comments));
          ]
      in

     Dream.respond
        ~headers:[ ("Content-Type", "application/json") ]
        (Yojson.Safe.to_string response)

let add_comment_handler request =
  match%lwt Dream.body request with
  | "" -> Dream.respond ~status:`Bad_Request "Empty body"
  | body -> (
      try%lwt
        let json = Yojson.Safe.from_string body in
        let open Yojson.Safe.Util in
        let page_url = json |> member "pageUrl" |> to_string in
        let author = json |> member "author" |> to_string in
        let email = json |> member "email" |> to_string_option in
        let website = json |> member "website" |> to_string_option in
        let content = json |> member "content" |> to_string in
        let parent_id = json |> member "parentId" |> to_string_option in

        (* Basic validation *)
        if String.length content = 0 then
          Dream.respond ~status:`Bad_Request "Comment content cannot be empty"
        else if String.length author = 0 then
          Dream.respond ~status:`Bad_Request "Author name cannot be empty"
        else if String.length page_url = 0 then
          Dream.respond ~status:`Bad_Request "Page URL cannot be empty"
        else (
          (* Store comment *)
          let comment = Comment.add_comment ~page_url
          ~author
          ~email
          ~website
          ~content ~parent_id in

          (* Return success response *)
          let response =
            `Assoc [ ("id", `String comment.Comment.id); ("status", `String "success") ]
          in
          Dream.respond ~status:`Created (Yojson.Safe.to_string response))
      with e ->
        Dream.respond ~status:`Bad_Request
          ("Invalid request format: " ^ Printexc.to_string e))

let routes = [
  Dream.get "/pagetalk.js" serve_js_handler;
  Dream.get "/pagetalk.css" serve_css_handler;
  Dream.get "/api/comments" get_comments_handler;
  Dream.post "/api/comments" add_comment_handler;
]

let run () =
  Dream.run ~port:3000 @@ Dream.logger
  @@ Dream.memory_sessions @@ cors_middleware
  @@ Dream.router (List.concat [routes; Admin.routes])
       

let () = run ()
