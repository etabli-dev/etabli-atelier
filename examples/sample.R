# Sample R — runs on the bundled WebR runtime (no network needed).
# Switch the kernel to R, then press Run. Text goes to Console, the plot to Plots.

x <- rnorm(200)
cat("n:", length(x), " mean:", round(mean(x), 3), " sd:", round(sd(x), 3), "\n")

hist(x, breaks = 20, col = "#28A745", border = "white",
     main = "200 draws from N(0, 1)", xlab = "value")
