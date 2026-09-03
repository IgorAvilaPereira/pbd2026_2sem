# mkdir myproject
# cd myproject
# python3 -m venv .venv
# . .venv/bin/activate
# pip install Flask
# pip install "psycopg[binary]"
# HelloWorld: https://flask.palletsprojects.com/en/stable/quickstart/
# Executar: flask --app hello run
# https://www.psycopg.org/psycopg3/docs/basic/usage.html
# https://www.psycopg.org/ >> Documentation >> Basic Usage




from flask import Flask # criar o objeto de app
from flask import render_template # para usar templates
from flask import request # para captar dados vindos do form
from flask import abort, redirect, url_for # para redirecionamentos e etc.
import psycopg # para trabalhar com banco
# objeto de app
app = Flask(__name__)

# rota de adicionar
@app.route("/adicionar", methods = ['GET', 'POST'])
def adicionar():
    # se cliquei no link da listagem
    if request.method == 'GET':
        return render_template('tela_adicionar.html')
    else:
        # se submeti o form (method POST): terei que realmente fazer a insercao
        # como conectar no banco
        with psycopg.connect(dbname="ifbet", user="postgres", password="postgres", port=5432, host="localhost") as conn:
            with conn.cursor() as cur:
                # pegando os valores dos campos preenchidos pelo usuario no form
                nome = request.form['nome']
                email = request.form['email']
                senha = request.form['senha']
                # criando a instrucao de insert
                cur.execute("INSERT INTO usuario (nome, email, senha) VALUES (%s, %s, md5(%s));", [nome, email, senha])
                # commitando a instrucao de insert
                conn.commit()

    # se tudo esta ok, redireciono novamente para a pagina/rota inicial - logo, aqui n tem html resultante            
    return redirect(url_for('hello_world'))


# rota inicial
@app.route("/")
def hello_world():
    with psycopg.connect(dbname="ifbet", user="postgres", password="postgres", port=5432, host="localhost") as conn:
        with conn.cursor() as cur:
            cur.execute("select * from usuario")
            return render_template('index.html', vetUsuario=cur.fetchall())

            # html = ""
            # for record in cur:
            #     html = html + record[1] +"<br><br>"
            # return html