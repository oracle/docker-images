.DEFAULT_GOAL := stacks

SHELL=/bin/bash
STACKS=elk haproxy-lb-to-apache haproxy-lb-to-nginx nginx-lb-to-apache nginx-lb-to-nginx prometheus

stacks: ## Loops over all the stacks and makes each one
	for s in $(STACKS); do \
	  pushd $$s && make && popd; \
	done

.PHONY: stacks
