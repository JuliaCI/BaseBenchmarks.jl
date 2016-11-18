
function perf_hdindexing{T}(u_i::AbstractArray{T, 6}, u_ip1::AbstractArray{T, 6})
  d1min = 3
  d1max = size(u_i, 5) - 2
  d2min = 3
  d2max = size(u_i, 4) - 2
  d3min = 3
  d3max = size(u_i, 3) - 2
  d4min = 3
  d4max = size(u_i, 2) - 2
  d5min = 3
  d5max = size(u_i, 1) - 2

  for d1 = d1min:d1max
    for d2 = d2min:d2max
      for d3 = d3min:d3max
        for d4 = d4min:d4max
          for d5 = d5min:d5max
            idx = (d5, d4, d3, d2, d1)
            kernel5(idx, u_i, u_ip1)
          end
        end
      end
    end
  end

  return nothing
end


function kernel5{T}(idx, u_i::AbstractArray{T,6}, u_ip1::AbstractArray{T,6})

  d1 = idx[1]
  d2 = idx[2]
  d3 = idx[3]
  d4 = idx[4]
  d5 = idx[5]
  
  delta_12 = 0.5
  delta_22 = 0.5
  delta_32 = 0.5
  delta_42 = 0.5
  delta_52 = 0.5
  
  u11_1 =  (1/12)*u_i[ d1 - 2, d2, d3, d4, d5, 1] +
           (-2/3)*u_i[ d1 - 1, d2, d3, d4, d5, 1] +
              (0)*u_i[ d1    , d2, d3, d4, d5, 1] +
            (2/3)*u_i[ d1 + 1, d2, d3, d4, d5, 1] +
          (-1/12)*u_i[ d1 + 2, d2, d3, d4, d5, 1]
  
  u22_1 =  (1/12)*u_i[ d1, d2 - 2, d3, d4, d5, 1] +
           (-2/3)*u_i[ d1, d2 - 1, d3, d4, d5, 1] +
              (0)*u_i[ d1, d2    , d3, d4, d5, 1] +
            (2/3)*u_i[ d1, d2 + 1, d3, d4, d5, 1] +
          (-1/12)*u_i[ d1, d2 + 2, d3, d4, d5, 1]
  
  u33_1 =  (1/12)*u_i[ d1, d2, d3 - 2, d4, d5, 1] +
           (-2/3)*u_i[ d1, d2, d3 - 1, d4, d5, 1] +
              (0)*u_i[ d1, d2, d3    , d4, d5, 1] +
            (2/3)*u_i[ d1, d2, d3 + 1, d4, d5, 1] +
          (-1/12)*u_i[ d1, d2, d3 + 2, d4, d5, 1]
  
  u44_1 =  (1/12)*u_i[ d1, d2, d3, d4 - 2, d5, 1] +
           (-2/3)*u_i[ d1, d2, d3, d4 - 1, d5, 1] +
              (0)*u_i[ d1, d2, d3, d4    , d5, 1] +
            (2/3)*u_i[ d1, d2, d3, d4 + 1, d5, 1] +
          (-1/12)*u_i[ d1, d2, d3, d4 + 2, d5, 1]
  
  u55_1 =  (1/12)*u_i[ d1, d2, d3, d4, d5 - 2, 1] +
           (-2/3)*u_i[ d1, d2, d3, d4, d5 - 1, 1] +
              (0)*u_i[ d1, d2, d3, d4, d5    , 1] +
            (2/3)*u_i[ d1, d2, d3, d4, d5 + 1, 1] +
          (-1/12)*u_i[ d1, d2, d3, d4, d5 + 2, 1]
  
  u_ip1[ d1, d2, d3, d4, d5, 2] = delta_12*u11_1 + delta_22*u22_1 + delta_32*u33_1 + 
                                  delta_42*u44_1 + delta_52*u55_1
  
  u11_2 =  (1/12)*u_i[ d1 - 2, d2, d3, d4, d5, 2] +
           (-2/3)*u_i[ d1 - 1, d2, d3, d4, d5, 2] +
              (0)*u_i[ d1    , d2, d3, d4, d5, 2] +
            (2/3)*u_i[ d1 + 1, d2, d3, d4, d5, 2] +
          (-1/12)*u_i[ d1 + 2, d2, d3, d4, d5, 2]
  
  u22_2 =  (1/12)*u_i[ d1, d2 - 2, d3, d4, d5, 2] +
           (-2/3)*u_i[ d1, d2 - 1, d3, d4, d5, 2] +
              (0)*u_i[ d1, d2    , d3, d4, d5, 2] +
            (2/3)*u_i[ d1, d2 + 1, d3, d4, d5, 2] +
          (-1/12)*u_i[ d1, d2 + 2, d3, d4, d5, 2]
  
  u33_2 =  (1/12)*u_i[ d1, d2, d3 - 2, d4, d5, 2] +
           (-2/3)*u_i[ d1, d2, d3 - 1, d4, d5, 2] +
              (0)*u_i[ d1, d2, d3    , d4, d5, 2] +
            (2/3)*u_i[ d1, d2, d3 + 1, d4, d5, 2] +
          (-1/12)*u_i[ d1, d2, d3 + 2, d4, d5, 2]
  
  u44_2 =  (1/12)*u_i[ d1, d2, d3, d4 - 2, d5, 2] +
           (-2/3)*u_i[ d1, d2, d3, d4 - 1, d5, 2] +
              (0)*u_i[ d1, d2, d3, d4    , d5, 2] +
            (2/3)*u_i[ d1, d2, d3, d4 + 1, d5, 2] +
          (-1/12)*u_i[ d1, d2, d3, d4 + 2, d5, 2]
  
  u55_2 =  (1/12)*u_i[ d1, d2, d3, d4, d5 - 2, 2] +
           (-2/3)*u_i[ d1, d2, d3, d4, d5 - 1, 2] +
              (0)*u_i[ d1, d2, d3, d4, d5    , 2] +
            (2/3)*u_i[ d1, d2, d3, d4, d5 + 1, 2] +
          (-1/12)*u_i[ d1, d2, d3, d4, d5 + 2, 2]
  
  u_ip1[ d1, d2, d3, d4, d5, 1] = delta_12*u11_2 + delta_22*u22_2 + delta_32*u33_2 + 
                                  delta_42*u44_2 + delta_52*u55_2
  
  
  return nothing
end

