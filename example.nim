import src/saucenao
import std/asyncdispatch
import std/options

var nao = initSauceNao(key=some readFile(".key"))
#var nao = initSauceNao()
echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromUrl("https://cdn.discordapp.com/attachments/484475887295791124/1089561249043460186/RDT_20230326_1630027094872649478175539.jpg")
#await nao.asyncFromFile("img.jpg")
