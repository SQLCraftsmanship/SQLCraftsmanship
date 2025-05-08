https://www.youtube.com/playlist?list=PL0Zuz27SZ-6MQri81d012LwP5jvFZ_scc

## General Commands

  * To check Version
    py -3 --version

  * To update pip
    python.exe -m pip install --upgrade pip

    pip list ==> to check all the packages installed

  * Install PyQt6
    Inside of the virtual environment you have to Run

    pip install PyQt6

    pip install pyqt6-tools

    PyQt6-tools designer

    pip install pyside6

  * Steps to create a new Virtual Environment
    https://www.youtube.com/watch?v=oN0cISyzWe8

    General 

    Check Python and Pip are install
        python --version
        pip --version
    
    Creae a new folder

    1. Run commands
        pip install virtualenv
        pip install virtualenvwrapper-win

    2. On the new folder Run
        python -m venv NameOfVirtualEnvironment

    3. Activate virtual enmvironment
        NameOfVirtualEnvironment\Script\activate.bat

    OPTIONAL
        We can use command pip freeze > requirements.txt to save all the dependencies in a single file and use the command pip install -r requirements.txt to install
        all the dependencies in a new Environment

  * Install Django
    -- Install Django
    pip install django Pillow django-ckeditor

    -- Start a project
    django-admin startproject NameOfTheProject

    -- Create main
    python manage.py startapp main
