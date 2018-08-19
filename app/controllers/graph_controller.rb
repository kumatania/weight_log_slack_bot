class GraphController < ApplicationController
  def show
    file_name = "tmp/#{params[:team]}_#{params[:user]}.txt"
    weights = {}
    token_info = []
    if File.exist?(file_name)
      File.open(file_name, 'r') do |f|
        f.each_line.with_index do |line, i|
          if i == 0
            token_info = line.chomp.split(' ')
          else
            split_line = line.chomp.split(' ')
            weights[split_line[0]] = split_line[1]
          end
        end
      end
      p weights.keys.to_json.html_safe
      token_created_at = DateTime.parse(token_info[0])
      diff = ((DateTime.now - token_created_at) * 24 * 60 * 60).to_i
      # 期限切れかtokenが古い
      if diff > 1000000 || token_info[1] != params[:token]
        weights = nil
      else
        @x = weights.keys.to_json.html_safe
        @y = weights.values.to_json.html_safe
        @y_min = weights.values.min.to_i - 5
        @y_max = weights.values.max.to_i + 5
      end
    end
    @weights = weights
  end
end
