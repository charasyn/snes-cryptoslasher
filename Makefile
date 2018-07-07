dirs := game

all: $(dirs)
clean: $(addprefix clean/,$(dirs))
.PHONY: all clean $(dirs) $(addprefix clean/,$(dirs))


$(dirs): %:
	$(MAKE) -C $@

$(addprefix clean/,$(dirs)): clean/%:
	$(MAKE) -C $(notdir $@) clean
