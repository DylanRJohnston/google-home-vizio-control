require! {
  'vizio-smart-cast': SmartCast
  express
  co
  util: { inspect }
  dotenv
}

dotenv.config!

app = express!
tv = new SmartCast process.env.TV_PI_ADDRESS, process.env.SMART_CAST_TOKEN


wait = (amount) ->
  resolve <-! new Promise _
  setTimeout (-> resolve!), amount


get = (url, f) ->
  req, res <- app.get url

  co f req, res
    .catch console.error


getCurrentInputName = -> tv.input.current!.then (.ITEMS[0].VALUE)
turnTheTvOn = -> tv.control.power.on!
isTheTVOff = -> tv.power.currentMode!.then (.ITEMS[0].VALUE == 0)


powerOn = co.wrap ->*
  yield turnTheTvOn! if yield isTheTVOff!

changeInput = co.wrap (name) ->*
  yield tv.input.set name
  until name == yield getCurrentInputName!
    yield wait 1000
  
triggerCEC = co.wrap (name) ->*
  yield changeInput 'CAST'
  yield wait 1000
  yield changeInput name


get '/playstation', (_, res) ->*
  yield powerOn!
  yield triggerCEC process.env.PLAYSTATION_INPUT
  res.status 200 .send ""

get '/switch', (_, res) ->*
  yield powerOn!
  yield triggerCEC process.env.SWITCH_INPUT
  res.status 200 .send!


app.listen 3000