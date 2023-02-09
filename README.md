# Donor Formatter

This app is designed to format .CSVs and .TXTs downloaded from state campaign finance sites. For it to work properly, it needs to receive **unaltered** files downloaded directly from the campaign sites. It is also still in *early* development, so errors will likely crop up. Please DM me on Slack or email me at jackson.rudoff@applecart.co with any comments, concerns, or error reports!


## File Types 

Kansas: .html (**NOTE**: These files download as `.xls` files. You have to manually change the file extension to `.html`.
Virginia: .xml
Massachusetts, Michigan, Montana: .txt

## Using the Site

Using this tool is fairly straightforward.

1\. Click ```Browse``` and select unaltered an donor file downloaded from a state campaign site. It should be structured as a list of **contributions** to a specific candidate.

2\. After the file has uploaded, select the correct state from the dropdown menu. You will know it has worked if a table outputs to the right of the upload panel. If it does not do this, then there is an issue with the file's formatting. *Please feel free to message me if this happens.* 

If it has worked correctly, your screen should look like this:
        
   ![donor_step_1](https://user-images.githubusercontent.com/62763243/215576983-fc467bb2-65a0-4510-8a1e-6529e80f3cca.png)

3\. Click the ```Download``` button, and choose a name for the file. Name it such that you will know it is the correctly formatted file.

4\. Done!

## In Progress

1. Adding a list of correct search portals (some campaign sites have multiple).
2. Adding states with weird formats.
3. Figuring out which states that have direct API access.
