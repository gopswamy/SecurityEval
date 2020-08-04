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
    (slot which) (slot value) (slot Explanation))

(deftemplate number (slot value))
(deftemplate number1 (slot value))
(deftemplate number2 (slot value))


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
(defrule AS1
    (answer (ident antivirus) (text yes))
    (answer (ident encrypt) (text yes))
    (answer (ident admin) (text no))
    =>
    (bind ?rate "Good")
    (bind ?ex "Antivirus is Installed. The data in the laptop is encrypted and the Admin rights are not with the user.")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS2
    (answer (ident antivirus) (text yes))
    (answer (ident encrypt) (text yes))
    (answer (ident admin) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Antivirus is Installed. The data in the laptop is encrypted, but the rating is average since the Admin are with the user and this allows users to installed uncertified Application")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS3
    (answer (ident antivirus) (text yes))
    (answer (ident encrypt) (text no))
    (answer (ident admin) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "Antivirus is Installed. The data in the laptop is not encrypted hence not secure, but Admin rights are not with the user.")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS4
    (answer (ident antivirus) (text yes))
    (answer (ident encrypt) (text no))
    (answer (ident admin) (text yes))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Antivirus is Installed. But the data is not secured and the admin rights are with the user which can lead to installation of uncertified applications. ")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS5
    (answer (ident antivirus) (text no))
    (answer (ident encrypt) (text yes))
    (answer (ident admin) (text no))
    =>
    (bind ?rate "Good")
    (bind ?ex "Antivirus is not Installed, but the data is encrypted and the admin rights for the system are not with the user.")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS6
    (answer (ident antivirus) (text no))
    (answer (ident encrypt) (text yes))
    (answer (ident admin) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Antivirus is not Installed, but the data is encrypted. The rating is average because the admin rights are with the user and uncertified application can be installed")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS7
    (answer (ident antivirus) (text no))
    (answer (ident encrypt) (text no))
    (answer (ident admin) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "No Antivirus, and no data encryption. Very less security.")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule AS8
    (answer (ident antivirus) (text no))
    (answer (ident encrypt) (text no))
    (answer (ident admin) (text yes))
    =>
    (bind ?rate "Bad")
    (bind ?ex "No Antivirus, no data encryption and admin rights with the user. Very less security.")
    (bind ?wh "Asset Security Rating")
    (assert
        (rating (which ?wh)(value ?rate) (Explanation ?ex))))

(defrule ES1
    (answer (ident wifi) (text yes))
    (answer (ident authentication) (text yes))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text yes))
    =>
    (bind ?rate "Good")
    (bind ?ex "Wifi is protected, two-level authentication for login, but even though there was breach all steps are taken to rectify" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES2
    (answer (ident wifi) (text yes))
    (answer (ident authentication) (text yes))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "Wifi is protected, two-level authentication for login, no steps were taken to fix the issue for the breach" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES3
    (answer (ident wifi) (text yes))
    (answer (ident authentication) (text no))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Wifi is protected, but there is no two-level authentication for login, but even though there was breach all steps are taken to rectify" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES4
    (answer (ident wifi) (text yes))
    (answer (ident authentication) (text no))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Wifi is protected,but there is no two-level authentication for login, no steps were taken to rectify the security breach" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES5
    (answer (ident wifi) (text no))
    (answer (ident authentication) (text yes))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Wifi is not protected and has risk of attacks, two-level authentication for login, but even though there was breach all steps are taken to rectify" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES6
    (answer (ident wifi) (text no))
    (answer (ident authentication) (text yes))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Wifi is not protected and has risk of attacks, two-level authentication for login, no steps were taken to rectify the issue for the breach" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES7
    (answer (ident wifi) (text no))
    (answer (ident authentication) (text no))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text yes))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Wifi is not protected, there is no two-level authentication for login, but even though there was breach all steps are taken to rectify, there is still risk for future attacks" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES8
    (answer (ident wifi) (text no))
    (answer (ident authentication) (text no))
    (answer (ident breach) (text yes))
    (answer (ident steps) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Wifi is not protected, there is no two-level authentication for login, there was a breach and no steps were taken to rectify the issue" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES9
    (answer (ident wifi) (text yes))
    (answer (ident authentication) (text no))
    (answer (ident breach) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "Wifi is protected,but there is no two-level authentication for login,no breach reported" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES10
    (answer (ident wifi) (text no))
    (answer (ident authentication) (text yes))
    (answer (ident breach) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "Wifi is not protected, two-level authentication for login is present, no breach reported" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES11
    (answer (ident wifi) (text no))
    (answer (ident authentication) (text no))
    (answer (ident breach) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Even though there is no breach reported, Wifi is not protected and there is no two-level authentication for login is present, hence there is higher chance for attacks" )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ES12
    (answer (ident wifi) (text yes))
    (answer (ident authentication) (text yes))
    (answer (ident breach) (text no))
    =>
    (bind ?rate "Good")
    (bind ?ex "Wifi is protected, two-level authentication for login available and no reports of breach. Very good infrastructure." )
    (bind ?wh "Network Environmental Security Rating")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex))))

(defrule ESA1
    (answer (ident ID) (text yes))
    (answer (ident sec) (text ?number&:(> ?number 6)))
    (answer (ident wfh) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Physical level security is good, but the last security awareness program is more than 6 months for employees and work from home is allowed which increases the risk of data breach" )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA2
    (answer (ident ID) (text yes))
    (answer (ident sec) (text ?number&:(< ?number 6)))
    (answer (ident wfh) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Physical level security is good, even though the last security awareness program is less than 6 months old, work from home is allowed which increases the risk of data breach" )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA3
    (answer (ident ID) (text no))
    (answer (ident sec) (text ?number&:(> ?number 6)))
    (answer (ident wfh) (text yes))
    =>
    (bind ?rate "Bad")
    (bind ?ex "No ID for employees hence no physical level security, the last security awareness program is more than 6 months for employees and work from home is allowed which increases the risk of data breach" )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA4
    (answer (ident ID) (text no))
    (answer (ident sec) (text ?number&:(< ?number 6)))
    (answer (ident wfh) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "No ID for employees hence no physical level security, the last security awareness program is less than 6 months for employees and work from home is allowed which increases the risk of data breach" )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA5
    (answer (ident ID) (text yes))
    (answer (ident sec) (text ?number&:(> ?number 6)))
    (answer (ident wfh) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "Physical security is good, and risk of data breach is low since there is no work from home. But the security awareness for employees is more than 6 months" )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA6
    (answer (ident ID) (text yes))
    (answer (ident sec) (text ?number&:(< ?number 6)))
    (answer (ident wfh) (text no))
    =>
    (bind ?rate "Good")
    (bind ?ex "Physical security is good, and risk of data breach is low since there is no work from home and employee security awareness is also less than 6 months" )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA7
    (answer (ident ID) (text no))
    (answer (ident sec) (text ?number&:(> ?number 6)))
    (answer (ident wfh) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "No physical security and security awareness program is also more than 6 months." )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))

(defrule ESA8
    (answer (ident ID) (text no))
    (answer (ident sec) (text ?number&:(< ?number 6)))
    (answer (ident wfh) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "No physical security and no Work from home(reduces risk of data breach) also security awareness program is also less than 6 months." )
    (bind ?wh "Employee Security Awareness")
    (assert
        (rating (which ?wh) (value ?rate)(Explanation ?ex))))


(defrule TSA1
    (answer (ident lasteval) (text ?number1&:(= ?number1 0)))
    =>
    (bind ?rate "No rating")
    (bind ?ex "No evaluation taken")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA2
    (answer (ident lasteval) (text ?number1&:(< ?number1 6)))
    (answer (ident tests) (text ?number2&:(< ?number2 50)))
    (answer (ident laststeps) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "Even though the last evaluation is less than 6 months old, less 50% percent of the systems were tested. The recommendations are implemented.")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA3
    (answer (ident lasteval) (text ?number1&:(> ?number1 6)))
    (answer (ident tests) (text ?number2&:(< ?number2 50)))
    (answer (ident laststeps) (text yes))
    =>
    (bind ?rate "Bad")
    (bind ?ex "The last evaluation is more than 6 months old and less than 50% systems are evaluated. Hence the data is pretty outdated and not accurate. ")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA4
    (answer (ident lasteval) (text ?number1&:(< ?number1 6)))
    (answer (ident tests) (text ?number2&:(> ?number2 50)))
    (answer (ident laststeps) (text yes))
    =>
    (bind ?rate "Good")
    (bind ?ex "The last evaluation is less than 6 months old and more than 50% systems evaluated. Also the recommendations from the last evaluation are taken up. ")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA5
    (answer (ident lasteval) (text ?number1&:(> ?number1 6)))
    (answer (ident tests) (text ?number2&:(> ?number2 50)))
    (answer (ident laststeps) (text yes))
    =>
    (bind ?rate "Average")
    (bind ?ex "The last evaluation is more than 6 months old and more than 50% systems evaluated. Even though the recommendations from the last evaluation are taken up, the evaluation results are outdated. ")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA6
    (answer (ident lasteval) (text ?number1&:(< ?number1 6)))
    (answer (ident tests) (text ?number2&:(< ?number2 50)))
    (answer (ident laststeps) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Even though the evaluation results are pretty new, less than 50% systems are evaluated and the recomendation from last evaluation are not taken up. The data is not accurate")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA7
    (answer (ident lasteval) (text ?number1&:(> ?number1 6)))
    (answer (ident tests) (text ?number2&:(< ?number2 50)))
    (answer (ident laststeps) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "Last evaluation is more than 6 months old, less than 50% systems evaluated and recommendation from the last evaluation are not taken up. The data is outdated and not accurate.")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA8
    (answer (ident lasteval) (text ?number1&:(< ?number1 6)))
    (answer (ident tests) (text ?number2&:(> ?number2 50)))
    (answer (ident laststeps) (text no))
    =>
    (bind ?rate "Average")
    (bind ?ex "The data evaluation results are pretty new and more than 50% of systems are evaluated. But recommendation from previous evaluation are not taken.")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

(defrule TSA9
    (answer (ident lasteval) (text ?number1&:(> ?number1 6)))
    (answer (ident tests) (text ?number2&:(> ?number2 50)))
    (answer (ident laststeps) (text no))
    =>
    (bind ?rate "Bad")
    (bind ?ex "The data evaluation results are pretty outdated and more than 50% of systems are evaluated. But recommendation from previous evaluation are not taken.")
    (bind ?wh "Security improvements ratings")
    (assert
        (rating (which ?wh) (value ?rate) (Explanation ?ex)))
    )

;module to print the final rating and explanation to the user
(defmodule rating)
(defrule print
    ?r1 <- (rating (which ?wh)(value ?rate) (Explanation ?ex ))
    =>
    (bind ?newline "
     ")
    (?*qfield* append ?newline)
    (?*qfield* append ?wh)
    (?*qfield* append ?newline)
    (?*qfield* append "Rating - ")
    (?*qfield* append ?rate)
    (?*qfield* append ?newline)
    (?*qfield* append "Explanation - ")
    (?*qfield* append ?ex)
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