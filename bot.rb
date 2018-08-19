require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

response = HTTP.post("https://slack.com/api/rtm.start", params: {
    token: ENV['SLACK_API_TOKEN']
})

rc = JSON.parse(response.body)

url = rc['url']

EM.run do
  # Web Socketインスタンスの立ち上げ
  socket = Faye::WebSocket::Client.new(url)

  #  接続が確立した時の処理
  socket.on :open do
    p [:open]
  end

  # RTM APIから情報を受け取った時の処理
  socket.on :message do |event|
    receive = JSON.parse(event.data)
    if receive['type'] == 'message'
      file_name = "tmp/#{receive['team']}_#{receive['user']}.txt"
      /^(?<me><@UCAPV35NG>) (?<text>.+)/ =~ receive['text']
      if me
        if text
          if text == 'graph'
            # グラフ出力URL返す
            file_content = []
            if File.exist?(file_name)
              File.open(file_name, 'r') do |f|
                f.each_line do |line|
                  file_content << line
                end
              end

              # token更新
              new_token = ((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(50).join
              file_content[0] = "#{DateTime.now} #{new_token}"
              File.open(file_name, 'w') do |f|
                file_content.each do |row|
                  f.puts row
                end
              end

              query = "?team=#{receive['team']}&user=#{receive['user']}&token=#{new_token}"
              p ENV['WEIGHT_LOGGER_HOST']

              socket.send({
                              type: 'message',
                              text: "グラフだしちゃる。15分くらいだけ有効ね\n#{ENV['WEIGHT_LOGGER_HOST']}/graph#{query}",
                              channel: receive['channel']
                          }.to_json)
            else
              socket.send({
                              type: 'message',
                              text: 'データないよ！登録して、、、',
                              channel: receive['channel']
                          }.to_json)
            end
          elsif text.to_f != 0
            # 体重を記録する
            if !File.exist?(file_name)
              File.open(file_name, 'w') do |f|
                f.puts("#{DateTime.now} #{((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(50).join}")
              end
            end
            File.open(file_name, 'a') do |f|
              f.puts("#{Date.today} #{text.to_f}")
            end
            socket.send({
                            type: 'message',
                            text: "#{text.to_f}kg を記録したよ",
                            channel: receive['channel']
                        }.to_json)
          else
            help = <<-"TEXT"
          つかいかた
          ・体重を記録する
          "@bukubuku 今日の体重"
          ・体重推移を見る
          "@bukubuku graph"
            TEXT
            socket.send({
                            type: 'message',
                            text: help,
                            channel: receive['channel']
                        }.to_json)
          end
        end
      end
    end

    # 接続が切断した時の処理
    socket.on :close do
      p [:close, event.code]
      socket = nil
      EM.stop
    end
  end
end

