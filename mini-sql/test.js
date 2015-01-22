var util = require('util');
var parser = require("./mini-sql").parser;

var tests = ["SELECT *",
	     "SELECT 1 + 1",
	     "SELECT ALL a",
	     "SELECT a, b, c FROM d WHERE a = 5.5 AND b = -1",
	     "SELECT a AS s1, b s2 FROM db.t WHERE s1 = 'abc' OR s2 IS NOT NULL",
	     "SELECT * FROM t WHERE NOT a > 9",
	     "SELECT * FROM t WHERE ! a > 9",
	     "SELECT * FROM t WHERE ! (a > 9)",
	     "SELECT * FROM t WHERE a > 9 AND ! b",
	     "SELECT DISTINCT m.* FROM abc AS m WHERE t BETWEEN -1 AND 5",
	     "SELECT l, m, n, SUM(p) FROM t WHERE q = 1.0 GROUP BY l, m, n",
	     "SELECT COUNT(*) FROM t WHERE x >= 0.5 AND y <> X'0fffa' ORDER BY z",
	     "SELECT AVG(t.a) FROM b t HAVING t.b > 0X5ABB",
	     "SELECT user, MAX(salary) FROM users GROUP BY user HAVING MAX(salary) > 10",
	     "SELECT CONCAT(last_name,', ',first_name) full_name FROM users ORDER BY full_name",
	     "SELECT * FROM t WHERE x < B'0011' ORDER BY y LIMIT 1, 1",
	     "SELECT * FROM t WHERE x = (SELECT MIN(x) FROM t)",
	     "SELECT TRUE WHERE EXISTS (SELECT * FROM t WHERE t > 0B01110)",
	     "SELECT t1.a, t1.b FROM t t1 WHERE t1.c IN (SELECT n FROM num)",
	     ];

tests.forEach(function (item) {
    console.log(item);
    var ast = parser.parse(item);
    console.log('--> %s', util.inspect(ast, {depth: 10}));
    //console.log('--> %s', eval(ast, []));
  });
