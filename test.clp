;importing the Java API's
(import javax.swing.*)
(import java.awt.*)
(import java.awt.event.*)
(import java.awt.Font)

;this would not reset the global functions when program start
(set-reset-globals FALSE)

;creating global variable for the UI frame
;Below commands create the UI
(defglobal ?*frame* = (new JFrame "Security Evaluator"))

(?*frame* setSize 700 700)
(?*frame* setVisible TRUE)

(defglobal ?*sum* = 0)

(defglobal ?*qfield* = (new JTextArea 5 40))
(bind ?scroll (new JScrollPane ?*qfield*))
;(defglobal ?*F* = (new Font Arial Font.BOLD 8))
;(?*qfield* setFont ?F)
((?*frame* getContentPane) add ?scroll)
(?*frame* repaint)

(defglobal ?*apanel* = (new JPanel))
(defglobal ?*afield* = (new JTextField 40))
(defglobal ?*afield-ok* = (new JButton OK))
(?*apanel* add ?*afield*)
(?*apanel* add ?*afield-ok*)
((?*frame* getContentPane) add ?*apanel*
	(get-member BorderLayout SOUTH))
(?*frame* validate)
(?*frame* repaint)

;creating a template for the question. It is like Java class
(deftemplate question 
    (slot text) (slot type) (slot ident))
;template for answer
(deftemplate answer
    (slot ident) (slot text))
;template for rating
(deftemplate rating
    (slot value) )

(deftemplate number (slot value))
(deftemplate number1 (slot value))
(deftemplate number2 (slot value))

(deftemplate score (slot sum1))


;functions to check if the inputs are valid
(deffunction is-of-type (?answer ?type)
    "Check that the answer has the right form"
    (if (eq ?type yes-no) then 
        (return (or (eq ?answer yes)(eq ?answer no)))
        else (if (eq ?type number or number1 or number2) then
            (return (numberp ?answer))
        else (return (> (str-length ?answer)0)))))

;functions to display the question
(deffunction ask-user (?question ?type)
    "Ask a question, and return the answer"
    ;(bind ?answer "")
    (bind ?newline "
    ")
    (bind ?s ?question " ")
    (bind ?s (str-cat ?newline ?s))
    
    (?*qfield* append ?s )
    (?*qfield* append ?newline)
    (?*afield* setText ""))
        

;module to ask questions to the user and updating the working memory
(defmodule ask)
(deffunction read-input (?EVENT)
    (bind ?text (sym-cat (?*afield* getText)))
    (assert (ask::user-input ?text)))

(bind ?handler
	(new jess.awt.ActionListener read-input (engine)))
(?*afield* addActionListener ?handler)
(?*afield-ok* addActionListener ?handler)

;rule to ask questions using the unique ID
(defrule ask::ask-question-by-id
    (declare (auto-focus TRUE))
    (MAIN::question (ident ?id) (text ?text) (type ?type))
    (not (MAIN::answer (ident ?id)))
    (MAIN::ask ?id)
    =>
    (ask-user ?text ?type)
    ((engine) waitForActivations))

;rule to collect user input
(defrule ask::collect-user-input
    (declare (auto-focus TRUE))
    (MAIN::question (ident ?id) (text ?text) (type ?type))
	(not (MAIN::answer (ident ?id)))
	?user <- (user-input ?input)
	?ask <- (MAIN::ask ?id)
    =>
    (?*qfield* append ?input )
    (printout t ?input)
    (if(eq ?input yes)then
        (++ ?*sum*))
        ;(printout t "sdf")
    (assert(score(sum1 ?*sum*)))
    (printout t ?*sum*)
    (if (is-of-type ?input ?type) then
		(assert (MAIN::answer (ident ?id) (text ?input)))
		(retract ?ask ?user)
		(return)
	else
		(retract ?ask ?user)
		(assert (MAIN::ask ?id))))

;list of question used by the system
(deffacts questions-data
    "The questions the systems can ask"
    (question (ident howmany) (type number) (text "How many Systems?(yes/no)"))
    (question (ident antivirus) (type yes-no) (text "Does the machines have virus protection?(yes/no)"))
    (question (ident encrypt) (type yes-no) (text "Are the data encrypted?(yes/no)"))
    (question (ident admin) (type yes-no) (text "Is the Administrator rights given to the employees?(yes/no)"))
    
    (question (ident wifi) (type yes-no) (text "Is the Enterprise Wifi password protected?(yes/no)"))
    (question (ident authentication) (type yes-no) (text "Does Login to Company Netowrk have two-level authentication?(yes/no)"))
    (question (ident breach) (type yes-no) (text "Was there a security breach in the past?(yes/no)"))
    (question (ident steps) (type yes-no) (text "Have steps been taken to rectify the issue after the breach?(yes/no)"))
    
    
    (question (ident ID) (type yes-no) (text "Do employees use ID card for physical authentication? Example: To enter office building, to enter restricted areas etc..(yes/no)"))
    (question (ident sec) (type number) (text "How frequent are the security awareness training for the employees?(enter in months)"))
    (question (ident wfh) (type yes-no) (text "Is work from home an option for the employees?(yes/no)"))
    
    
    (question (ident lasteval) (type number1) (text "When was the last evaluation performed(in months)(Enter '0' if 1st time)?"))
    (question (ident tests) (type number2) (text "What percent of system were security evaluated?"))
    (question (ident laststeps) (type yes-no) (text "Were the recommendation implemented from last evaluation?(yes/no)"))
	)
    
    
    
;module which evaluates the rating
;Different rules are configured to fire the question
(defmodule evaluate)
(defrule virus
    =>
    (assert (ask antivirus)))
(defrule encrypt
    =>
    (assert (ask encrypt)))
(defrule admin
    =>
    (assert (ask admin)))
(defrule wifi
    =>
    (assert (ask wifi)))
(defrule authentication 
    => 
    (assert (ask authentication)))
(defrule breach
    =>
    (assert (ask breach)))
;Hierarchical rule, depending on the breach answer, steps is asked
(defrule steps
    (answer (ident breach) (text yes))
    =>
    (assert (ask steps)))
(defrule ID
    =>
    (assert (ask ID)))
(defrule sec
    =>
    (assert (ask sec)))
(defrule wfh
    =>
    (assert (ask wfh)))
(defrule lasteval
    =>
    (assert (ask lasteval)))
(defrule tests
    (answer (ident lasteval) (text ?number1&:(> ?number1 0)))
    =>
    (assert (ask tests)))
(defrule laststeps
    (answer (ident lasteval) (text ?number1&:(> ?number1 0)))
    =>
    (assert (ask laststeps)))


;module to compute the rating
;Rules are configured to fire once the facts are obtained
(defmodule compute)
(defrule A
    (score {sum1 == 0})
    =>
    (bind ?rate "Bad")
    (assert
          (rating  (value ?rate) )))

(defrule B
    (score {sum1 == 1})
    =>
    (bind ?rate "Bad")
    (assert
          (rating  (value ?rate) )))

(defrule C
    (score {sum1 == 2})
    =>
    (bind ?rate "Bad")
    (assert
          (rating  (value ?rate) )))

(defrule D
    (score {sum1 == 3})
    =>
    (bind ?rate "Bad")
    (assert
          (rating  (value ?rate) )))

(defrule e
    (score {sum1 == 4})
    =>
    (bind ?rate "Average")
    (assert
          (rating  (value ?rate) )))

(defrule F
    (score {sum1 == 5})
    =>
    (bind ?rate "Average")
    (assert
          (rating  (value ?rate) )))

(defrule G
    (score {sum1 == 6})
    =>
    (bind ?rate "Average")
    (assert
          (rating  (value ?rate) )))

(defrule H
    (score {sum1 == 7})
    =>
    (bind ?rate "Good")
    (assert
          (rating  (value ?rate) )))

(defrule I
    (score {sum1 == 8})
    =>
    (bind ?rate "Good")
    (assert
          (rating  (value ?rate) )))

 (defrule J
     (score {sum1 == 9})
     =>
     (bind ?rate "Good")
     (assert
           (rating  (value ?rate) )))

(defrule K
    (score {sum1 == 10})
    =>
    (bind ?rate "Good")
    (assert
          (rating  (value ?rate) )))





;module to print the final rating and explanation to the user
(defmodule rating)
(defrule print
    ?r1 <- (rating (value ?rate))
    =>
    (bind ?newline "
     ")
    (?*qfield* append ?newline)
    ;(?*qfield* append ?wh)
    (?*qfield* append ?newline)
    (?*qfield* append "Rating - ")
    (?*qfield* append ?rate)
    (?*qfield* append ?newline)
    ;(?*qfield* append "Explanation - ")
    ;(?*qfield* append ?ex)
    (?*qfield* append ?newline)
    ;(printout t " "crlf)
    ;(printout t ?wh crlf)
    ;(printout t "Rating - "?rate crlf)
    ;(printout t "Explanation - "?ex crlf)
    ;(printout t " "crlf)
    (retract ?r1))

(reset)
(focus  evaluate compute rating)
(run)