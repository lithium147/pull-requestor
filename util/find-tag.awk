# trying to combine lines
# /<[^>]*$/{ l=l$0}
# !/<[^>]*$/{ print l$0; l=""}

# !/<project/ -- project tag is normally split of multiple lines, so just exclude it

!/<project/ && !/<[?]/ && !/<!/ && !/<.*>.*<[/].*>/ && /<.*>/{
    if ($1 ~ /<[/]/ ) {
        level--
    } else {
        level++
    }
    # level is -1 for some reason, need to investigate
    if(level <= 0 && $1 == tag) {
        found=NR
    }
#    print level " " NR " " $0
}
END {
    print found
}
