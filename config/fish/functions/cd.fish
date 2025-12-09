# function cd
# z $argv && ls
# end
function cd
    if z $argv
        set -l num_items (count *)
        if test $num_items -lt 15
            ls
        end
    end
end
function ..
    cd ..
end

function ...
    cd ../..
end

function ....
    cd ../../..
end

function .....
    cd ../../../..
end

function ......
    cd ../../../../..
end
