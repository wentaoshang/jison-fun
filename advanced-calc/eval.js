var util = require('util');
var parser = require("./calculator").parser;

function eval(input, env) {
  switch (input[0]) {
  case 'ADD': return eval(input[1], env) + eval(input[2], env);
  case 'SUB': return eval(input[1], env) - eval(input[2], env);
  case 'MUL': return eval(input[1], env) * eval(input[2], env);
  case 'DIV': return eval(input[1], env) / eval(input[2], env);
  case 'POW': return Math.pow(eval(input[1], env), eval(input[2], env));
  case 'NOT': return !(eval(input[1], env));
  case 'MOD': return eval(input[1], env) % eval(input[2], env);
  case 'ABS': return Math.abs(eval(input[1], env));
  case 'NEG': return -1 * eval(input[1], env);
  case 'IF':
    if (eval(input[1], env))
      return eval(input[2], env);
    else
      return eval(input[3], env);
  case 'LET':
    var new_env = env.slice(0);
    new_env.push({name: input[1], value: eval(input[2], env)});
    return eval(input[3], new_env);
  case 'VAR':
    for (var i = env.length - 1; i >= 0; i--)
      {
	if (env[i].name == input[1])
	  return env[i].value;
      }
    throw new Error('variable undefined');
  case 'SEQ':
    eval(input[1], env);
    return eval(input[2], env);
  default: return input;
  }
}

var tests = ['2 * 4.1',
	     '5 + 1 * 2; 0.5',
	     '5 * (-2)',
	     '5 * |-2|',
	     'if true then if false then 0 else 1 else 0',
	     'let x = 1 + 2 in x * 2',
	     'let x = 1 in 1 - x',
	     'let x = 1 in -x',
	     'let x = 1 in (let x = 2 in x; x + 1)'
	     ];

tests.forEach(function (item) {
    var ast = parser.parse(item);
    console.log(util.inspect(ast, {depth: 5}));
    console.log('--> %s', eval(ast, []));
  });

