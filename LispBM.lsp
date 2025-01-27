(def currenttoset 0) ;-1-0-1 used for setting the throttle
(def throttle 0) ;0-1 thumbthrottle value
(def throttleReleased 0) ;used to indicate throttle has been released after pressing cruise
(def cruise 1) ;1-0 cruise control input. 1 means button is not pressed.
(def cruiseMode 0) ;0 check if cruising should start - 1 start cruising, keep cruising, or stop cruising
(def cruisetimer 101) ;used to count how long it's been since cruise was disabled. Don't allow a bunch of accidental clicks to keep enabling cruise.
(def cruiseReleased 0) ;used to indicate cruise button has been released after pressing
;(def maxMotorCurrent (conf-get 'l-current-max))
;Fixed variables
(def cruisecooldown 100) ;1 second

(defun stopCruise ()
	(progn
		;(print "stopping Cruise")
		(setvar 'cruiseMode 0)
		(setvar 'cruisetimer 0)
		(setvar 'currenttoset 0)
		;(gpio-hold 'pin-tx 0)
		(set-current 0)
	)
)

(defun startCruise ()
	(progn
		;(print "enabling cruiseMode")
		(setvar 'currenttoset (get-duty))
		(setvar 'cruiseMode 1)
		(setvar 'cruiseReleased 0)
		(setvar 'throttleReleased 0)
	)
)

(loopwhile t
	(progn
		(setvar 'throttle (get-adc-decoded 0))
		(setvar 'cruise (gpio-read 'pin-tx)) ;Returns 1 if the pin is high, 0 otherwise. 0 is cruise control button is pressed
		;If cruising for first time, enable crusing, else see if brake, throttle, or cruise have been touched and stop cruising
		(if (= cruiseMode 1)
			(progn
				(if (> (get-adc-decoded 1) 0) ;Brake has been pressed. Stop cruising
					(stopCruise)
				)
				(if (= cruiseReleased 1)
					(if (< cruise 1) ;Cruise button has been clicked at least twice. Stop cruising
						(stopCruise)
					)
				)
				(if (= throttleReleased 1)
					(if (> throttle 0) ;Throttle has been twisted since cruise enabled. Stop cruising
						(stopCruise)
					)
				)
				(if (= cruiseReleased 0)
					(if (= cruise 1) ;Cruise has been released - indicate as such
						(setvar 'cruiseReleased 1)
					)
				)
				(if (= throttleReleased 0) ;If throttle has not been indicated released, check
					(if (= throttle 0) ;Throttle has been released - indicate as such
						(setvar 'throttleReleased 1)
					)
				)
				(set-current-rel currenttoset 0.015)
				;(gpio-hold 'pin-tx 1)
				;(app-adc-override 3 1)
			)
		)

		;If not cruising see if its time to cruise, X time has to have passed since cruise was enabled, no brake, throttle has to be high
		(if (= cruiseMode 0)
			(progn
				(if (<= cruisetimer cruisecooldown) ;Its been less than X seconds since cruise was disabled
					(setvar 'cruisetimer (+ cruisetimer 1))
				)
				;(print "in cruiseMode 0 IF")
				(if (= cruise 0) ;Cruise button is being pressed
					(if (> throttle 0) ;Throttle is active
						(if (> cruisetimer cruisecooldown) ;Its been at least X seconds since cruise was last disabled
							(startCruise)
						)
					)
				)
			)
		)

		;100 hz
		(sleep 0.01)
	)
)
