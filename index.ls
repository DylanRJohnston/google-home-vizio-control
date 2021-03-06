require! {
  'vizio-smart-cast': SmartCast
  'body-parser': bodyParser
  crypto: { timingSafeEqual }
  util: { inspect: _inpsect }
  express
  co
  dotenv
}

dotenv.config!

app = express!
app.use bodyParser.text!

tv = new SmartCast process.env.TV_PI_ADDRESS, process.env.SMART_CAST_TOKEN
secret = Buffer.from process.env.SECRET_INPUT

secretEqual = ->
  try
    timingSafeEqual secret, Buffer.from it
  catch
    false

wait = (amount) ->
  resolve <-! new Promise _
  setTimeout resolve, amount

post = (url, f) ->
  req, res <- app.post url

  if secretEqual req.body
     co f res
      .catch console.error
  else
    console.error "Called with incorrect secret #{req.body}" 
    res.status 403 .send ""


getCurrentInputName = -> tv.input.current!.then (.ITEMS[0].VALUE)
turnTheTVOn = -> tv.control.power.on!
turnTheTVOff = -> tv.control.power.off!
isTheTVOff = -> tv.power.currentMode!.then (.ITEMS[0].VALUE == 0)

powerOn = co.wrap ->*
  yield turnTheTVOn! if yield isTheTVOff!

powerOff = co.wrap ->*
  yield turnTheTVOff! unless yield isTheTVOff!

changeInput = co.wrap (name) ->*
  console.log "Changing input to: #{name}"

  until name == yield getCurrentInputName!
    console.log "Input change loop: #{name}"
    
    yield tv.input.set name
    yield wait 1000
  
  console.log "Done changing to: #{name}"


triggerCEC = co.wrap (name) ->*
  yield changeInput 'CAST'
  yield changeInput name


inputs =
  * name: 'playstation'
    input: process.env.PLAYSTATION_INPUT
  * name: 'switch'
    input: process.env.SWITCH_INPUT
  * name: 'chromecast'
    input: 'cast' 

inputs.map ({ name, input }) ->
  post "/#{name}", (res) ->*
    console.log "Turning on the #{name}"

    yield powerOn!
    yield triggerCEC input
    res.status 200 .send ""

post "/off", (res) ->*
  yield powerOff!
  res.status 200 .send ""

app.listen 3000