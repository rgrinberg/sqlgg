
open OUnit
open RA
open Sql.Type
open Stmt

let tt ?msg stmt scheme params =
  let print_scheme = RA.Scheme.to_string in
  let print_params = Stmt.params_to_string in
  let (s1,p1,_) =
    try
      Parser.parse_stmt stmt
    with
    | _ -> assert_failure "tt failed"
  in
  assert_equal ?msg ~printer:print_scheme scheme s1;
  assert_equal ?msg ~printer:print_params params p1

let test () =
  tt "CREATE TABLE test (id INT, str TEXT, name TEXT)"
     []
     [];
  tt "SELECT str FROM test WHERE id=?"
     [attr "str" Text]
     [Next,Some Int];
  tt "SELECT x,y+? AS z FROM (SELECT id AS y,CONCAT(str,name) AS x FROM test WHERE id=@id*2) ORDER BY x,x+y LIMIT @lim"
     [attr "x" Text; attr "z" Int]
     [Next,Some Int; Named "id", Some Int; Named "lim",Some Int; ];
  tt "select test.name,other.name as other_name from test, test as other where test.id=other.id + @delta"
     [attr "name" Text; attr "other_name" Text]
     [Named "delta", Some Int];
  tt "select test.name from test where test.id = @x + ? or test.id = @x - ?"
     [attr "name" Text;]
     [Named "x", Some Int; Next, Some Int; Named "x", Some Int; Next, Some Int;];
  ()

(* From MySQL 5.4 refman: 12.2.8.1. JOIN Syntax *)
let test_join_result_cols () =
  Tables.reset ();
  tt "CREATE TABLE t1 (i INT, j INT)" [] [];
  tt "CREATE TABLE t2 (k INT, j INT)" [] [];
  tt ~msg:"natural" "SELECT * FROM t1 NATURAL JOIN t2" [attr "j" Int; attr "i" Int; attr "k" Int;] [];
  tt ~msg:"using" "SELECT * FROM t1 JOIN t2 USING (j)" [attr "j" Int; attr "i" Int; attr "k" Int;] [];
  ()

let run () =
  let tests =
  [
    "simple" >:: test;
    "JOIN result columns" >:: test_join_result_cols;
  ]
  in
  let test_suite = "main" >::: tests in
  ignore (run_test_tt test_suite)
