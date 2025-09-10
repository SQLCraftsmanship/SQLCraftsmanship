
"""
Improvement
    1. Create a function to validate that the email direction that the user imput is okay
    2. Put everything on method
"""

# Import module to send email
from email.message import EmailMessage
import ssl
import smtplib
import re

# Create function to validate email address
def f_ValidateEmailAddress(par_EmailReceiver):
      
    # Regular expression pattern to match a valid email address
    EmailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

    # Use the re.match() function to check if the email matches the pattern
    if re.match(EmailPattern, par_EmailReceiver):
        f_SendEmail()
    else:
        return ("The email address has an error. Please checkit!!")
       
# Create function to send email
def f_SendEmail():
    
    # Create sender and pass vars
    var_EmailSender = 'liberatori.lucas@gmail.com'
    var_PassSender = 'hsso dobe efft vkpz'

    # Create email structure
    var_Subecjt = "This is my first app on Python"
    var_EmailBody = """
    Viva el Racing Club de Avellaneda!!!
    """

    # Define send email
    inst_EM = EmailMessage()
    inst_EM['From'] = var_EmailSender
    inst_EM['To'] = var_EmailReceiver
    inst_EM['subject'] = var_Subecjt
    inst_EM.set_content(var_EmailBody)

    # 
    var_Context = ssl.create_default_context()

    # Send the email
    with smtplib.SMTP_SSL('smtp.gmail.com', 465, context=var_Context) as smtp:
        smtp.login(var_EmailSender, var_PassSender)
        smtp.sendmail(var_EmailSender, var_EmailReceiver, inst_EM.as_string())


# ******************************************************************************
# Execute the app
# ******************************************************************************

# Create seceiver email
var_EmailReceiver = input("Enter email address to send the mail: ")

f_ValidateEmailAddress(var_EmailReceiver.lower())
