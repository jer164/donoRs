# Donor Formatter

This app is designed to format `.csv`, `.txt`, `HTML` and `xml` files downloaded from state and city campaign finance portals. For it to work properly, it needs to receive **unaltered** files downloaded directly from the campaign sites. It is also in constant development, so errors will likely crop up. Please DM me on Slack or email me at jackson.rudoff@applecart.co with any comments, concerns, or error reports!

This website's core functionality is also available as a `PlumbeR` API to be implemented in a pipeline or other data stream. Please shoot me message if you have any use for this. 

## File Types 

**Kansas**, **Missouri**, **Maryland**: .html (*NOTE*: These files download as `.xls` files. You have to manually change the file extension to `.html`.

**Virginia**: .xml

**Massachusetts**, **Montana**, **Florida**: .txt

**Michigan**: .sh ––> .txt (you have to change the extension)

**All others**: .csv 

## Using the Site

Using this tool is fairly straightforward.

1\. Click ```Browse``` and select unaltered an donor file downloaded from a state campaign site. It should be structured as a list of **contributions** to a specific candidate.

2\. After the file has uploaded, select the correct state from the dropdown menu. You will know it has worked if a table outputs to the right of the upload panel. If it does not do this, then there is an issue with the file's formatting. *Please feel free to message me if this happens.* 

If it has worked correctly, your screen should look like this:
        
   ![donor_step_1](https://user-images.githubusercontent.com/62763243/224132387-ee8d69ca-1512-45c9-852f-1bc8a0b11636.png)

3\. Click the ```Download``` button, and choose a name for the file. Name it such that you will know it is the correctly formatted file.

4\. Done!

## Philadelphia Search Portal

This app supports direct searching of candidates in the Philadelphia campaign finance system. 

1\. Select Philadelphia from the dropdown menu. On first load-up of the website, it may be a bit slow. 

2\. Search for your candidate using their first name, last name, full name, or campaign committee name. Use your instincts to decide if the query is returning the correct amount or the correct people. I strongly recommend you find the campaign committee name to ensure you have the right search query. 

3\. Proceed with steps 3 and 4 from above!

## Tricky Files/Sites

#### Michigan

This website is really jank in general, but especially in terms of its output. Because of what I'm guessing is a compiler error on their end, the file it outputs has the `.sh` file extension. However, the fix is relatively simple: just change the file extension manually to `.txt`. 

#### Florida

The website has a misplaced quotation mark somewhere which messes up the file it outputs. The best method for getting a clean file is to just manually to a complete rename when downloading the file. I recommend something like this: "firstname_lastname.**txt**"

#### Kansas, Missouri, Maryland

The file will download as a "spreadsheet," according to the websites. This is a lie, they are actually `HTML` tables. The fix is easy, just change the file extension to **.html**. 

## FAQ

#### **How do I know I have a file that is compatible?**

Compatible file types will have each row as an *individual contributor*, with at least some address information and a date/amount for the contribution

#### **Can I use data from outside sources like Open Secrets or a non-profit/interest group?**

No. Typically, these files are missing the identifying information that ABBA needs to match the donors to a target.

#### **How can I tell if the output file has missing data or other errors?**

The main indicator that something has gone wrong is if you upload a file and a table doesn't output, even after waiting for several minutes. If you click `Download` and the output file is called "downloadData," this is also an indication that the file-handler couldn't parse what you provided. 

The helper statistics outputted by the web app also serve as hints about the file integrity. For example, if you inputted a file for a congressman from Michigan but the most common state is Florida, this is a sign that the data might have issues and may not be worth adding to their profile. 


## In Progress

1. Patching errors and fixing address fields in the wake of ABBA updates. 
2. Continuing to add city-level websites. 
3. PDF support (unlikely to ever be implemented without more help). 
