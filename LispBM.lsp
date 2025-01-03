(define duty 0) ;-1-0-1 used for setting the dutycycle
(define dutytoset 0) ;-1-0-1 used for setting the dutycycle
(define throttle 0) ;0-1 thumbthrottle value
(define throttleReleased 0) ;used to indicate throttle has been released after pressing cruise
(define brake 0) ;0-1 Brake input
(define cruise 0) ;0-1 cruise control input
(define cruiseMode 0) ;0 do nothing - 1 cruising
(define cruisetimer 301) ;used to count how long it's been since cruise was disabled
(define cruiseReleased 0) ;used to indicate cruise button has been released after pressing

;Fixed variables
(define cruisecooldown 300) ;3 seconds

(loopwhile t
    (progn
        (setvar 'throttle (get-adc-decoded 0))
    		(setvar 'brake (get-adc-decoded 1))
    		(setvar 'cruise (gpio-read 'pin-tx)) ;Returns 1 if the pin is high, 0 otherwise.
        (setvar 'duty (get-duty)) ;Get current speed of motor
            
    		;If cruising for first time, enable crusing, else see if brake, throttle, or cruise have been touched and stop cruising
    		(if (= cruiseMode 1)
    		  (if (> brake 0) ;Brake has been pressed.  Stop cruising
    			  (progn 
    				  (setvar 'cruiseMode 0)
    		  		(setvar 'cruisetimer 0)
    		  		(setvar 'dutytoset 0)
    		  		(set-duty 0)
    		  	)
      		)
      		(if (= cruiseReleased 1)
      			(if (> cruise 0) ;Cruise button has been clicked at least twice. Stop cruising
      				(progn 
      					(setvar 'cruiseMode 0)
      					(setvar 'cruisetimer 0)
      					(setvar 'dutytoset 0)
      					(set-duty 0)
      				)
      			)
      		)
      		(if (= throttleReleased 1)
      			(if (> throttle 0) ;Throttle has been twisted since cruise enabled. Stop cruising
      				(progn 
      					(setvar 'cruiseMode 0)
      					(setvar 'cruisetimer 0)
      					(setvar 'dutytoset 0)
      					(set-duty 0)
      				)
      			)
      		)
      		(if (= cruiseReleased 0)
      			(if (= cruiseMode 1) ;If cruise button still pushed and hasnt been canceled yet, set the motor speed
      				(progn
               (set-duty dutytoset)
              )
      			)
      			(if (= cruise 0) ;Cruise has been released - indicate as such
      				(progn
               (setvar 'cruiseReleased 1)
              )
      			)
      		)
      		(if (= throttleReleased 0) ;If throttle has not been indicated released, check
      			(if (= cruiseMode 1) ;If throttle still twisted and cruise hasnt been canceled yet, set the motor speed
      				(progn
                 (set-duty dutytoset)
              )
      			)
      			(if (= throttle 0) ;Throttle has been released - indicate as such
      				(progn
                (setvar 'throttleReleased 1)
              )
      			)
      		)
    		)

    		;If not cruising see if its time to cruise, X time has to have passed since cruise was enabled, no brake, throttle has to be high
    		(if (= cruiseMode 0)
    			(if (<= cruisetimer cruisecooldown) ;Its been less than X seconds since cruise was disabled
    				(progn 
    					(setvar 'cruisetimer (+ cruisetimer 1))
    				)
    			)
    			(if (> cruise 0) ;Cruise button is being pressed
    				(if (> throttle 0) ;Throttle is active
    					(if (> cruisetimer cruisecooldown) ;Its been at least X seconds since cruise was last disabled
    						(progn 
    							(setvar 'dutytoset duty)
    							(setvar 'cruiseMode 1)
    							(setvar 'cruiseReleased 0)
    							(setvar 'throttleReleased 0)
    						)
    					)
    				)
    			)
    		)
        
        ;100 hz
        (sleep 0.01)      
    )
)
