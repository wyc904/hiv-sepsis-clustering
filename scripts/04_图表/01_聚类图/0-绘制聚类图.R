setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# Load required libraries
library(factoextra)
library(ggplot2)

# Create the clustering visualization
p <- fviz_cluster(
  object = list(data = data_cluster, cluster = data$cluster),
  geom = "point",                    # Use points only for simplicity
  ellipse.type = "norm",            # Normal confidence ellipses
  ellipse.level = 0.95,             # 95% confidence ellipses for clarity
  show.clust.cent = TRUE,           # Show cluster centroids
  star.plot = FALSE,                # Disable star plot to reduce clutter
  pointsize = 2,                    # Moderate point size for visibility
  labelsize = 10,                   # Font size for labels (JAMA-compliant)
  main = paste("GMM Clustering (K =", best_k, ")"), # Concise, descriptive title
  xlab = "Principal Component 1",   # Clear axis labels (customize as needed)
  ylab = "Principal Component 2",
  ggtheme = theme_minimal(base_size = 12, base_family = "Arial") # JAMA-compliant theme
)

# Customize the plot further to meet JAMA standards
p <- p + 
  scale_color_manual(values = c("#ff0000", "#0000ff", "#2CA02C", "#D62728", "#9467BD")) + # Colorblind-friendly palette
  scale_fill_manual(values = c("#ff0000", "#0000ff", "#2CA02C", "#D62728", "#9467BD")) +  # Match fill to color
  theme(
    text = element_text(family = "Arial", size = 12, color = "black"), # Sans-serif font, JAMA-compliant size
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"), # Centered, bold title
    axis.title = element_text(size = 12),                     # Clear axis titles
    axis.text = element_text(size = 12, color = "black"),     # Legible axis text
    legend.position = "bottom",                               # Legend at bottom to avoid plot overlap
    legend.title = element_blank(),                           # Remove legend title for simplicity
    legend.text = element_text(size = 10),                    # Legible legend text
    panel.grid = element_blank(),                             # Remove gridlines to reduce clutter
    plot.background = element_rect(fill = "white", color = NA), # White background
    panel.border = element_rect(color = "black", fill = NA)   # Black border for clarity
  )

# Display the plot
print(p)

# Save the plot in high-resolution for JAMA submission
# ggsave(
#   filename = "gmm_clustering_plot.tiff", # TIFF format for JAMA
#   plot = p,
#   width = 6,                            # Width in inches (JAMA suggests 5–7 inches)
#   height = 4,                           # Height in inches
#   dpi = 300,                            # High resolution for print
#   compression = "lzw"                   # LZW compression for TIFF
# )