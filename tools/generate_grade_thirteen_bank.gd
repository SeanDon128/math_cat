extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_13.json"

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_topic("Integration", 25, 0)
    _add_topic("Integration Techniques", 25, 1)
    _add_topic("Applications of Integration", 15, 2)
    _add_topic("Sequences and Series", 20, 3)
    _add_topic("Convergence and Divergence", 15, 4)
    _add_topic("Taylor Series", 15, 5)
    _add_topic("Multivariable Functions", 20, 6)
    _add_topic("Partial Derivatives", 20, 7)
    _add_topic("Multiple Integrals", 15, 8)
    _add_topic("Vector Calculus", 20, 9)
    _add_topic("First-Order Differential Equations", 25, 10)
    _add_topic("Applications of Differential Equations", 15, 11)
    _add_topic("Exponential Growth and Decay Models", 15, 12)
    _add_topic("Matrices", 20, 13)
    _add_topic("Matrix Operations", 20, 14)
    _add_topic("Determinants", 15, 15)
    _add_topic("Vectors", 20, 16)
    _add_topic("Eigenvalues and Eigenvectors", 15, 17)
    _add_topic("Groups", 15, 18)
    _add_topic("Rings", 10, 19)
    _add_topic("Fields", 10, 20)
    _add_topic("Modular Arithmetic (Modern Algebra)", 20, 21)
    _add_topic("Open Sets", 10, 22)
    _add_topic("Closed Sets", 10, 23)
    _add_topic("Continuity", 10, 24)
    _add_topic("Homeomorphisms", 10, 25)
    _add_topic("Modular Arithmetic (Cryptography)", 15, 26)
    _add_topic("Prime Numbers", 10, 27)
    _add_topic("Public Key Concepts", 10, 28)
    _add_topic("RSA Foundations", 10, 29)
    _add_topic("Logic", 15, 30)
    _add_topic("Mathematical Proofs", 15, 31)
    _add_topic("Set Theory", 15, 32)
    assert(records.size() == 520, "Grade 13 question bank must contain 520 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 13 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 13 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, prompt: String, correct: String, wrong: Array[String], uses_pi: bool = false) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    assert(choices.size() >= 3, "Grade 13 choices must be distinct: %s" % prompt)
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    records.append({"grade": 13, "topic": topic, "difficulty": "hard", "uses_pi": uses_pi, "question": prompt, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _add_topic(topic: String, count: int, kind: int) -> void:
    for index in range(count):
        var value := index + 2
        match kind:
            0:
                var integral_value := value * value * value
                _record(topic, "Evaluate ∫ from 0 to %d of %dx dx." % [value, value], str(integral_value), [str(integral_value - 1), str(integral_value + 1), str(integral_value + 2)])
            1:
                match posmod(index, 2):
                    0: _record(topic, "Which method is most direct for ∫ x e^(%dx²) dx?" % value, "u-substitution with u = %dx²" % value, ["integration by parts", "partial fractions", "trigonometric substitution"])
                    _: _record(topic, "Evaluate ∫ %d/x dx on x > 0." % value, "%d ln(x) + C" % value, ["%d/x + C" % value, "x ln(x) + C", "e^(%dx) + C" % value])
            2:
                var area := value * value * value / 2
                _record(topic, "The area under y = %dx from x = 0 to x = %d is:" % [value, value], str(area), [str(area - 1), str(area + 1), str(area + 2)])
            3:
                _record(topic, "For aₙ = %d/%dⁿ, what is lim n→∞ aₙ?" % [value, value + 1], "0", ["1", str(value), "diverges"])
            4:
                match posmod(index, 2):
                    0: _record(topic, "Does Σ from n=1 to ∞ of 1/n^%d converge?" % value, "converges", ["diverges by the harmonic series", "equals 1", "oscillates"])
                    _: _record(topic, "Does Σ from n=1 to ∞ of %d/n diverge?" % value, "yes, by comparison with the harmonic series", ["no, because terms approach zero", "no, by the ratio test", "yes, because it is geometric"])
            5:
                match posmod(index, 3):
                    0: _record(topic, "The Taylor series for sin(%dx) centered at 0 begins with:" % value, "%dx - %dx³/3!" % [value, value * value * value], ["1 - %dx²/2!" % (value * value), "%dx + %dx²/2!" % [value, value * value], "%dx³/3!" % (value * value * value)])
                    1: _record(topic, "At what center is the Maclaurin series for f_%d expanded?" % value, "0", ["1", "π", "the nearest critical point"])
                    _: _record(topic, "Which is the quadratic Taylor approximation of e^(%dx) at x = 0?" % value, "1 + %dx + %dx²/2" % [value, value * value], ["%dx + %dx²" % [value, value * value], "1 + %dx²/2" % (value * value), "e^(%d x²)" % value])
            6:
                _record(topic, "For f(x, y) = %dx² + y², what is f(%d, %d)?" % [value, value, value + 1], str(value * value * value + (value + 1) * (value + 1)), [str(value * value + (value + 1) * (value + 1)), str(value * value * value), str(value + value + 1)])
            7:
                var partial_value := 2 * value * value * value
                _record(topic, "For f(x, y) = %dx²y, what is ∂f/∂x at (%d, 1)?" % [value, value], str(partial_value), [str(partial_value - 1), str(partial_value + 1), str(value * value)])
            8:
                var double_integral := value * value
                _record(topic, "Evaluate ∬ over [0,%d] × [0,1] of %d dA." % [value, value], str(double_integral), [str(double_integral - 1), str(double_integral + 1), str(double_integral + 2)])
            9:
                match posmod(index, 2):
                    0: _record(topic, "For F(x, y) = <%dx, %dy>, what is div F?" % [value, value + 1], str(2 * value + 1), [str(value), "0", str(value * (value + 1))])
                    _: _record(topic, "What is the gradient of f(x, y) = %dx + %dy?" % [value, value + 1], "<%d, %d>" % [value, value + 1], ["<%d, %d>" % [value + 1, value], "<0, 0>", "<%d, %d>" % [2 * value, 2 * value + 2]])
            10:
                match posmod(index, 2):
                    0: _record(topic, "Which function solves y' = %dy with y(0) = 1?" % value, "e^(%dx)" % value, ["%de^x" % value, "x^%d" % value, "e^x + %d" % value])
                    _: _record(topic, "For y' = %dx with y(0) = 0, what is y(x)?" % value, "%dx²/2" % value, ["%dx" % value, "x²/%d" % value, "%dx²" % value])
            11:
                _record(topic, "A cooling model is T' = -%d(T - 20). What is the equilibrium temperature?" % value, "20", ["0", str(-value), "depends on the initial temperature"])
            12:
                _record(topic, "A population follows P' = %dP. If P(0) = 1, which is P(t)?" % value, "e^(%dt)" % value, ["%dt" % value, "t^%d" % value, "e^t + %d" % value])
            13:
                _record(topic, "For A = [[%d, 1], [0, %d]], what is trace(A)?" % [value, value + 1], str(2 * value + 1), [str(value), str(value + 1), str(value * (value + 1))])
            14:
                _record(topic, "If A is %d×%d and B is %d×%d, what is the size of AB?" % [value, value + 1, value + 1, value + 2], "%d×%d" % [value, value + 2], ["%d×%d" % [value + 1, value + 1], "%d×%d" % [value + 2, value], "%d×%d" % [value, value + 1]])
            15:
                _record(topic, "What is det([[%d, 1], [0, %d]])?" % [value, value + 1], str(value * (value + 1)), [str(2 * value + 1), str(value + 1 - value), "0"])
            16:
                _record(topic, "What is the dot product of <%d, %d> and <1, -1>?" % [value, value + 1], "-1", ["1", str(2 * value + 1), str(value)])
            17:
                _record(topic, "What is an eigenvalue of diagonal matrix diag(%d, %d)?" % [value, value + 1], str(value), [str(value + 1), str(2 * value + 1), "0"])
            18:
                _record(topic, "For a candidate group G_%d, which condition is required?" % value, "every element has an inverse", ["multiplication must commute", "the set must contain real numbers", "every element must be idempotent"])
            19:
                _record(topic, "For ring R_%d, which structure must its addition form?" % value, "an abelian group", ["a field", "a cyclic group", "only a semigroup"])
            20:
                _record(topic, "Which property distinguishes field F_%d from a general ring?" % value, "every nonzero element has a multiplicative inverse", ["addition is associative", "it has a zero element", "multiplication distributes over addition"])
            21:
                var residue := posmod(value * value + 1, value + 1)
                _record(topic, "What is %d mod %d?" % [value * value + 1, value + 1], str(residue), [str(residue + 1), str(residue + 2), str(residue + 3)])
            22:
                _record(topic, "In R, which set containing %d.5 is open?" % value, "(%d, %d)" % [value, value + 1], ["[%d, %d]" % [value, value + 1], "{%d}" % value, "[%d, %d)" % [value, value + 1]])
            23:
                _record(topic, "In R, which bounded interval with endpoints %d and %d is closed?" % [value, value + 1], "[%d, %d]" % [value, value + 1], ["(%d, %d)" % [value, value + 1], "(%d, %d]" % [value, value + 1], "(%d, %d) ∩ Q" % [value, value + 1]])
            24:
                _record(topic, "Which epsilon-delta statement describes continuity of f_%d at a?" % value, "x near a implies f(x) near f(a)", ["f is differentiable at a", "f has an inverse at a", "f(a) is a local maximum"])
            25:
                _record(topic, "A map h_%d: X → Y is a homeomorphism only if it is:" % value, "a continuous bijection with continuous inverse", ["a differentiable bijection", "a linear isometry", "a function preserving distances"])
            26:
                _record(topic, "Compute %d^2 mod %d for an RSA-style calculation." % [value, value + 1], str(posmod(value * value, value + 1)), [str(value), str(value + 1), str(value * value)])
            27:
                _record(topic, "Which property defines a candidate prime p_%d > 1?" % value, "it has exactly two positive divisors", ["it is odd", "it is not divisible by 2", "it has no negative divisors"])
            28:
                _record(topic, "In user %d's public-key system, which key may be shared openly?" % value, "the public key", ["the private key", "the session secret", "the factorization of the modulus"])
            29:
                _record(topic, "For RSA modulus n_%d, security is based primarily on the difficulty of:" % value, "factoring a large composite modulus", ["adding large integers", "computing a gcd", "testing a small prime"])
            30:
                _record(topic, "What is the negation of 'for every x, P_%d(x)'?" % value, "there exists x such that not P_%d(x)" % value, ["for every x, not P_%d(x)" % value, "there exists x such that P_%d(x)" % value, "not P_%d(x) for no x" % value])
            31:
                _record(topic, "Which method proves claim C_%d by assuming its negation and deriving a contradiction?" % value, "proof by contradiction", ["direct proof", "proof by cases", "proof by induction"])
            _:
                _record(topic, "If A has %d elements and B has %d elements with no overlap, how many elements are in A ∪ B?" % [value, value + 1], str(2 * value + 1), [str(value * (value + 1)), str(value + 1), str(2 * value)])