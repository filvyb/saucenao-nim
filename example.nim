import src/saucenao
import std/asyncdispatch
import std/options

var nao = initSauceNao(key=some readFile(".key"), numres=2)
#var nao = initSauceNao()
echo $nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
#echo nao.fromFile("img.jpg")
echo nao.fromUrl("https://derpicdn.net/img/view/2023/3/28/3071725.jpg")
#echo waitFor asyncFromFile(addr nao, "img.jpg")
