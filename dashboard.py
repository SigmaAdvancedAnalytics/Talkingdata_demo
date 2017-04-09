from sqlalchemy import create_engine
from flask import Flask
from flask import render_template
import pandas as pd
import yaml
import json
import sys
import os

app = Flask(__name__)

#Load configuration information for the web backend database
try:
	#initialise the config.yml file
	script_path = os.path.dirname(os.path.abspath(sys.argv[0]))
	with open(script_path+"/config/config.yml", 'r') as ymlfile:
		config = yaml.load(ymlfile)
	#set the database connection parameters based on the config.ini file
	host = config['PostgreSQL']['host']
	port = config['PostgreSQL']['port']
	dbname = config['PostgreSQL']['dbname']
	user  = config['PostgreSQL']['user']
	password = config['PostgreSQL']['password']
except:
	print("Unable to read config.ini ",sys.exc_info())
	exit()

#Establish a connection to the web backend database
try:
	engine = create_engine(r"postgresql://"+user+":"+password+"@"+host+"/"+dbname)
	dataframe = pd.read_sql_table(table_name='csv_talkingdata',con=engine)
except:
	print("Unable to load source datafile")
	exit()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/data")
def get_data():
    
    return dataframe.to_json(orient='records')

if __name__ == "__main__":
    app.run(host='0.0.0.0',port=5000)