using JuMP, HiGHS
using Pkg
#DOUG AND CHURCH
function maxMatchingLP(W)
    n = size(W, 1)
    model = Model(HiGHS.Optimizer)
    @variable(model, x[1:n, 1:n], Bin)
    @objective(model, Max, sum(x[i, j] * W[i, j] for i in 1:n, j in 1:n))
    for i in 1:n
        @constraint(model, sum(x[i, j] for j in 1:n) == 1)
    end
    for j in 1:n
        @constraint(model, sum(x[i, j] for i in 1:n) == 1)
    end
    optimize!(model)
    X = Int[value(x[i, j]) for i in 1:n, j in 1:n]
    return X

end


function marketPrices(W)
    n = size(W, 1)
    model = Model(HiGHS.Optimizer)
    @variable(model, p[1:n] >= 0)
    @variable(model, u[1:n] >= 0)
    for i in 1:n
        for j in 1:n
            @constraint(model, (p[j] + u[i]) >= W[i, j])
        end
    end
    @objective(model, Min, sum(p) + sum(u))
    optimize!(model)
    return value.(p)
end


function create_equality_graph(matrix, matchings)
    result_matrix = zeros(Int, size(matrix))
    #println("this is the matchings $matchings")
    for i in 1:size(matrix, 1)
     
        max_value = maximum(matrix[i, :])
        indices = findall(x -> x == max_value, matrix[i, :])
        #println("These are the indices for i $indices")
        
        un_matched_indices = filter(index -> !("seller_$(index)" in keys(matchings)), indices)
        
        if isempty(un_matched_indices)
            max_index = indices[1] 
        else
            max_index = un_matched_indices[1] 
        end
        
        result_matrix[i, max_index] = max_value
    end
    
    return result_matrix
end
function sixthtryisthecharm(W)
    matchings = Dict()
    first_equality_graph = create_equality_graph(W, matchings)
    matching_checker = falses(size(W, 1))
    final_graph = zeros(Int, size(W))
    seller_values = zeros(Int, size(W, 2))
    max_second_value = 0
    max_second_buyer = 0
    max_second_seller = 0
    passedBy = false
    
    
    # Find the maximum value in the equality graph and its position
    max_value = maximum(first_equality_graph)
    max_pos = findfirst(isequal(max_value), first_equality_graph)
    #println("This is max_value: $max_value and this is max_pos: $max_pos")
    buyer_index, seller_index = Tuple(max_pos)
    #println("This is the max value $max_value")
    #println("These are the buyer and seller indices $buyer_index and $seller_index")
    # Check if this seller is exclusive
    while length(matchings) < length(W)
        
        max_difference = Inf
        if (max_value === nothing || max_pos === nothing)
            #println("Reassigning max_val & pos")
            max_value = max_second_value
            buyer_index = max_second_buyer
            seller_index = max_second_seller
            #println("AFTER NOTHING IF STATEMENT: This is max_value: $max_value and this is max_pos: $buyer_index, this is max seller index: $seller_index")
        end

        competing_buyers = findall(x -> x != 0, first_equality_graph[:, seller_index])
        #println("This is competing buyers: $competing_buyers before mods")
        competing_buyers = filter(buyer -> W[buyer, seller_index] != 0, competing_buyers) #!(haskey(matchings, "buyer_$buyer")&& matchings["buyer_$buyer"] != (max_value, seller_index)) 
        updated_competing_buyers = []

        for buyer in competing_buyers
            buyer_key = "buyer_$buyer"  
            if haskey(matchings, buyer_key)
                if matchings[buyer_key][2] == seller_index 
                    push!(updated_competing_buyers, buyer) 
                end
            else
                push!(updated_competing_buyers, buyer)
            end
        end

        competing_buyers = updated_competing_buyers
        total_connected_buyers = length(competing_buyers)
        #println("This is competing buyers: $competing_buyers, this is total_connected_buyers $total_connected_buyers")
        
        if total_connected_buyers == 1
            # Exclusive seller, add to final graph
            final_graph[buyer_index, seller_index] = max_value
            matchings["buyer_$(buyer_index)"] = (max_value, seller_index) 
            if !haskey(matchings, "seller_$(seller_index)")
                matchings["seller_$(seller_index)"] = (0, buyer_index) 
            end
            matching_checker[buyer_index] = true;
            #println("this is max_value at tcp if $max_value")
            #println("IF TCB: These are the buyer and seller indices $buyer_index and $seller_index")
            max_pos = nothing
            max_value = nothing
            first_equality_graph = create_equality_graph(W, matchings)
            if all(count(>(0), first_equality_graph[i,:]) == 1 for i in axes(first_equality_graph, 1)) &&
                all(count(>(0), first_equality_graph[:, i]) == 1 for i in axes(first_equality_graph, 2))
                     return first_equality_graph
 
             end
            #println("This is the if b == 1 eq graph $first_equality_graph")
            #println("This is final graph in tcp = 1 section $final_graph")
            for i in 1:length(matching_checker)
                if !matching_checker[i]
                    favorite, seller = findmax(W[i, :])
                    #println("This is the favorite kn the if statement: $favorite")
                    if haskey(matchings, "seller_$seller")
                        _, currentOwner = matchings["seller_$seller"]
                        if haskey(matchings,"buyer_$currentOwner")
                            currentValue, _ = matchings["buyer_$currentOwner"]
                            buyer_index = currentOwner
                            max_value = currentValue
                            seller_index = seller
                            max_pos = currentOwner
                            #println("IN THE MATCHING CHECKER: This is max_value: $max_value and this is max_pos: $max_pos")
                            passedBy = true
                        end
                    end
                end
            end
            if passedBy
                #println("Made it here")
            else
                return final_graph
            end
        else
            
            
           # println("Im in the else")

            for b in competing_buyers
               # println("This is the b: $b")
               # println("This is the buyer index: $buyer_index")
                #if b == buyer_index
                #    continue
                #end
                seller_values = first_equality_graph[b, :]
                favorite = seller_values[seller_index]
                #println("This is the favorite $favorite")
                
             

                tempW = copy(convert(Matrix{Float64}, W))
                tempW[b, seller_index] = -Inf
                #println("This is the value at this point $tempW")
                second_highest_value, second_highest_seller_index = findmax(tempW[b,:])
                #println("This is max value and index for findmax temp $second_highest_value, $second_highest_seller_index")
                second_highest_value = Int(second_highest_value)  
                
                #println("This is the second favorite $second_highest_value and its index $second_highest_seller_index")
                
                
                difference = favorite - second_highest_value
                #seller_values
                #println("This is the difference in the else $difference")
    
                if difference <= max_difference && difference > 0 
                    max_difference = difference
                    
                     max_second_value = second_highest_value
                    max_second_buyer = b
                    max_second_seller = second_highest_seller_index
                    #println("This is max difference $max_difference, this is max second val $max_second_seller, this is max
                    #second buyer $max_second_buyer, and this is max second seller $max_second_seller")
                    
                end
            end
            
     
            
            final_graph[buyer_index, seller_index] = max_value - max_difference
            matchings["buyer_$(buyer_index)"] = (max_value - max_difference, seller_index)
            matchings["seller_$(seller_index)"] = (max_difference, buyer_index)
            matching_checker[buyer_index] = true
            #println("This is the buyer in matchings: $(matchings["buyer_$(buyer_index)"]) and this is the seller $(matchings["seller_$(seller_index)"])")
            W[:, seller_index] = max.(0, W[:, seller_index] .- max_difference)
            #println("This is the new $W after seller changed")
            first_equality_graph = create_equality_graph(W, matchings)
            if all(count(>(0), first_equality_graph[i,:]) == 1 for i in axes(first_equality_graph, 1)) &&
               all(count(>(0), first_equality_graph[:, i]) == 1 for i in axes(first_equality_graph, 2))
                    return first_equality_graph

            end
            #println("This is the change in the second equality graph $first_equality_graph")
            #print("This is the end loop final graph $final_graph")
            #println("This is max_second_value: $max_second_value \n\n")
            max_pos = nothing
            max_value = nothing
            
        end

    end
    
    #println("reached the end")
    return final_graph
end
 

function maxMatchingHungarian(W)
    sixthtryisthecharm(W)
end


# Example usage

m1 = [7 3 4
      2 1 0 
      5 0 1]

m2 = [1 2 0
      0 1 2
      2 0 1]

m3 = [7	 4	3	5
      6	 8	5	9
      9	 4	4	2
      3	 8	7	4]

m4 = [4 0 
      2 0  ] 