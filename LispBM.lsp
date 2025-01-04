(define duty 0) ;-1-0-1 used for setting the dutycycle
(define dutytoset 0) ;-1-0-1 used for setting the dutycycle
(define throttle 0) ;0-1 thumbthrottle value
(define throttleReleased 0) ;used to indicate throttle has been released after pressing cruise
(define brake 0) ;0-1 Brake input
(define cruise 1) ;1-0 cruise control input
(define cruiseMode 0) ;0 do nothing - 1 cruising
(define cruisetimer 101) ;used to count how long it's been since cruise was disabled
(define cruiseReleased 0) ;used to indicate cruise button has been released after pressing

;Fixed variables
(define cruisecooldown 100) ;1 seconds

(defun stopCruise ()
    (progn
		(print "stopping Cruise")
		(setvar 'cruiseMode 0)
		(setvar 'cruisetimer 0)
		(setvar 'dutytoset 0)
		(set-duty 0)
	)
)

(loopwhile t
	(progn
		(setvar 'throttle (get-adc-decoded 0))
		(setvar 'brake (get-adc-decoded 1))
		(setvar 'cruise (gpio-read 'pin-tx)) ;Returns 1 if the pin is high, 0 otherwise.
		(setvar 'duty (get-duty)) ;Get current speed of motor
		;If cruising for first time, enable crusing, else see if brake, throttle, or cruise have been touched and stop cruising
		(if (= cruiseMode 1)
			(progn
				(if (> brake 0) ;Brake has been pressed.	Stop cruising
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
						(progn
							(print "cruise released")
							(setvar 'cruiseReleased 1)
						)
					)
				)
				(if (= throttleReleased 0) ;If throttle has not been indicated released, check
					(if (= throttle 0) ;Throttle has been released - indicate as such
						(progn
							(print "throttle released")
							(setvar 'throttleReleased 1)
						)
					)
				)
				(set-duty dutytoset)
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
					(progn
						;(print "in cruise < 1 IF")
						(if (> throttle 0) ;Throttle is active
							(progn
								(print "in throttle > 0 IF")
								(if (> cruisetimer cruisecooldown) ;Its been at least X seconds since cruise was last disabled
									(progn
										(print "enabling cruiseMode")
										(setvar 'dutytoset duty)
										(setvar 'cruiseMode 1)
										(setvar 'cruiseReleased 0)
										(setvar 'throttleReleased 0)
									)
								)
							)
						)
					)
				)
			)
		)

		;100 hz
		(sleep 0.01)
	)
)
