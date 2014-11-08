
require 'net/http'

img_idx = 0

(0..11).each do |y|
  (0..16).each do |x|

    tile_name = "#{x}_#{y}.png"

    # plate 11
    id = "510d47e2-0962-a3d9-e040-e00a18064a99"
  
    # plate 10
    #id = "510d47e2-0961-a3d9-e040-e00a18064a99" 
    Net::HTTP.start("access.nypl.org") { |http|
      resp = http.get("/image.php/#{id}/tiles/0/13/#{tile_name}")
      puts resp

      out_name = img_idx.to_s.rjust(3, "0") 
      img_idx += 1

      open(out_name+".png","wb") { |file|
        file.write(resp.body)
      }
    }

  end
end
