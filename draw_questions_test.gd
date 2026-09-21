extends SceneTree

func _init():
    var question_bank_script = load('res://autoload/question_bank.gd')
    if not question_bank_script:
        printerr('Failed to load question_bank.gd')
        quit(1)
        return

    var question_bank = question_bank_script.new()
    if not question_bank:
        printerr('Failed to instantiate question_bank')
        quit(1)
        return

    for i in range(200):
        var question = question_bank.get_question(1)
        if not question:
            printerr('Question ', i, ' is null!')
            quit(1)
            return
        
        var choices = question.choices
        if choices.size() != 4:
            printerr('Question ', i, ' does not have exactly 4 choices: ', choices)
            quit(1)
            return
            
        var unique_choices = {}
        for choice in choices:
            unique_choices[choice] = true
            var choice_val = choice.to_int()
            if choice_val < 0 or choice.begins_with('-'):
                printerr('Question ', i, ' has a negative choice: ', choice)
                quit(1)
                return
                
        if unique_choices.size() != 4:
            printerr('Question ', i, ' does not have 4 unique choices: ', choices)
            quit(1)
            return
            
        var correct_answer = question.correct_answer
        if not unique_choices.has(correct_answer):
            printerr('Question ', i, ' choices do not contain correct answer ', correct_answer, ': ', choices)
            quit(1)
            return
            
    print('SUCCESS: 200 Grade 1 questions successfully drawn and verified!')
    quit(0)

