# Pairing instructions for the PE653 and PE953
Source: [Barrett Richardson](https://community.smartthings.com/t/intermatic-pe653-pool-control-system/936/239?u=philh30)

1. 953 choose Reset Device {clears the 653}
2. 653 push Include button {wipes programming, Include light starts blinking}
3. 953 choose Reset Controller, choose ‘reset net & config’
4. From ST app choose ‘Add things’
5. 653 push Include button
6. App should pair and prompt to select name, handler, app, etc
7. 953 choose Controller Copy {another non-intuitive step, this adds the remote to ST}
8. 953 choose Receive Net Only
9. 953 should report ‘Successful’ and lock up. {really! at least on the software rev I am on, I think v3.1}
10. 953 remove and replace battery {I am guessing this is where I lose you…}
11. 953 choose Include device
12. 653 push Include button {one more time!}
13. 953 should report ‘successful’
14. Voila!