require! {
  'vizio-smart-cast': SmartCast
  'body-parser': bodyParser
  crypto: { timingSafeEqual }
  util: { inspect }
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
turnTheTvOn = -> tv.control.power.on!
isTheTVOff = -> tv.power.currentMode!.then (.ITEMS[0].VALUE == 0)


powerOn = co.wrap ->*
  yield turnTheTvOn! if yield isTheTVOff!

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

post '/playstation', ->*
  console.log "Turning on playstation"
  yield powerOn!
  yield triggerCEC process.env.PLAYSTATION_INPUT
  it.status 200 .send ""

post '/switch', ->*
  console.log "Turning on switch"
  yield powerOn!
  yield triggerCEC process.env.SWITCH_INPUT
  it.status 200 .send ""

post '/cast', ->*
  console.log "Turning on chromecast"
  yield powerOn!
  yield changeInput 'CAST'
  it.status 200 .send ""

app.listen 3000