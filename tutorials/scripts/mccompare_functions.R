
# Load the blast results comparing curated libraries
LoadBlastComparison2 <- function(
  blast_out_MCHelper_vs_lib1,
  blast_out_MCHelper_vs_lib2,
  species,
  strain,
  comparison,
  reduce_hits = TRUE) {

  blast1 <- data.table::fread(blast_out_MCHelper_vs_lib1, sep = "\t")
  blast2 <- data.table::fread(blast_out_MCHelper_vs_lib2, sep = "\t")

  colnames(blast1) <- c(
    "qseqid1", "sseqid1", "pident1", "length1", "mismatch1", "gapopen1", "qstart1", "qend1", "sstart1", "send1", "evalue1", "bitscore1"
  )

  colnames(blast2) <- c(
    "qseqid2", "sseqid2", "pident2", "length2", "mismatch2", "gapopen2", "qstart2", "qend2", "sstart2", "send2", "evalue2", "bitscore2"
  )
  # Reduce to best hit per query
  if (reduce_hits) {
    blast1 <- blast1 %>%
      group_by(qseqid1) %>%
      slice_max(order_by = bitscore1, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      as.data.frame()

    blast2 <- blast2 %>%
      group_by(qseqid2) %>%
      slice_max(order_by = bitscore2, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      as.data.frame()
  }

  blast <- full_join(
    blast1, blast2,
    by = c("qseqid1" = "qseqid2")
  )

  blast$species <- species
  blast$strain <- strain
  blast$compare <- comparison

  # Split the query and ubject names 
  blast <- blast %>%
  separate_wider_regex(sseqid1,
    c(id1 = "[^#]+", "#",
      class1 = "[^/]+", "/?",
      order1 = "[^/]*", "/?",
      superfamily1 = ".*"),
      cols_remove = FALSE
    ) %>%
  separate_wider_regex(sseqid2,
    c(id2 = "[^#]+", "#",
      class2 = "[^/]+", "/?",
      order2 = "[^/]*", "/?",
      superfamily2 = ".*"),
      cols_remove = FALSE
    )

  blast <- blast %>%
  mutate(
    seq_match = case_when(
      !is.na(pident1) & !is.na(pident2) & pident1 >= 95 & pident2 >= 95 ~ "Perfect, 95-100",
      !is.na(pident1) & !is.na(pident2) & pident1 >= 80 & pident2 >= 80 ~ "Present, 80",
      !is.na(pident1) & !is.na(pident2) & pident1 >= 70 & pident2 >= 70 ~ "Present, 70",
      (!is.na(pident1) & !is.na(pident2)) & (pident1 < 70 & pident2 < 70) ~ "Present, <70",
      is.na(pident1) ~ "Missing from lib1",
      is.na(pident2) ~ "Missing from lib2"
    ),
    seq_match_score = case_when(
      !is.na(pident1) & !is.na(pident2) & pident1 >= 95 & pident2 >= 95 ~ 5,
      !is.na(pident1) & !is.na(pident2) & pident1 >= 80 & pident2 >= 80 ~ 4,
      !is.na(pident1) & !is.na(pident2) & pident1 >= 70 & pident2 >= 70 ~ 3,
      (!is.na(pident1) & !is.na(pident2)) & (pident1 < 70 & pident2 < 70) ~ 2,
      is.na(pident1) ~ 1,
      is.na(pident2) ~ 0
    ),
    class_match = case_when(
        is.na(pident1) ~ "Missing from lib1",
        is.na(pident2) ~ "Missing from lib2",
        class1 == class2 & order1 == order2 & superfamily1 == superfamily2 ~ "Class, Order, Superfamily",
        class1 == class2 & order1 == order2 & superfamily1 != superfamily2 ~ "Class, Order",
        class1 == class2 & order1 != order2 & superfamily1 != superfamily2 ~ "Class",
        class1 != class2 & order1 != order2 & superfamily1 != superfamily2 ~ "None"
      )
  )

  blast <- blast %>%
    mutate(
      across(where(is.character), na_if, ""),
      across(where(is.character), replace_na, "None")
    )

  blast <- blast %>%
  mutate(
    classification1 = paste(class1, order1, superfamily1, sep = "/"),
    classification2 = paste(class2, order2, superfamily2, sep = "/")
  )

  # === Output directory ===
  output_dir <- paste0("output/lib_compare/", species, "/", strain)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # === Filter and write missing IDs ===
  missing_lib1 <- blast %>%
    filter(seq_match == "Missing from lib1") %>%
    select(qseqid1) %>%
    mutate(qseqid1 = gsub("#.*", "", qseqid1))

  missing_lib2 <- blast %>%
    filter(seq_match == "Missing from lib2") %>%
    select(qseqid1) %>%
    mutate(qseqid1 = gsub("#.*", "", qseqid1))

  # Filenames
  file_lib1 <- file.path(output_dir, "/missing_from_lib1.csv")
  file_lib2 <- file.path(output_dir, "/missing_from_lib2.csv")

  # Write files
  writeLines(missing_lib1$qseqid1, file_lib1)
  writeLines(missing_lib2$qseqid1, file_lib2)

  # Optionally return blast data frame if needed
  return(blast)
}


PlotBlastBarMatches2 <- function(blast_input) {
  df <- blast_input %>%
    group_by(
        classification1,
        seq_match
        ) %>%
      summarize(
        n = n()
        ) %>%
      mutate(
        seq_match = factor(seq_match, levels = c("Missing from lib1", "Missing from lib2", "Present, <70", "Present, 70", "Present, 80", "Perfect, 95-100"))
      )
  bp1 <- df %>%
    ggplot(aes(fill=seq_match, y=n, x=reorder(classification1, n))) + 
    geom_bar(position="stack", stat="identity") +
    theme_bw() +
    scale_fill_manual(values = palette_seq_match) +
    coord_flip()

  bp2 <- df %>%
    ggplot(aes(fill=seq_match, y=n, x=reorder(classification1, n))) + 
    geom_bar(position="fill", stat="identity") +
    theme_bw() +
    scale_fill_manual(values = palette_seq_match) +
    coord_flip()
  
  # Now plot for the missing from query broken down by classification:
  df2 <- blast_input %>%
    filter(seq_match == "Missing from lib1") %>%
    group_by(
      classification2,
      seq_match
    ) %>%
    summarize(
      n = n()
    )

  bp3 <- df2 %>%
    ggplot(aes(fill=seq_match, y=n, x=reorder(classification2, n))) + 
    geom_bar(position="stack", stat="identity", show.legend = FALSE) +
    theme_bw() +
    scale_fill_manual(values = palette_seq_match) +
    coord_flip()
  
  df3 <- blast_input %>%
    filter(seq_match == "Missing from lib2") %>%
    group_by(
      classification1,
      seq_match
    ) %>%
    summarize(
      n = n()
    )

  bp4 <- df3 %>%
    ggplot(aes(fill=seq_match, y=n, x=reorder(classification1, n))) + 
    geom_bar(position="stack", stat="identity", show.legend = FALSE) +
    theme_bw() +
    scale_fill_manual(values = palette_seq_match) +
    coord_flip()
  
  bp1 + bp2 + bp3 + bp4 +
  plot_layout(guides = 'collect', ncol = 1) +
  plot_annotation(tag_levels = 'A')
}


lib_compare_copy_missing_TEs <- function(df, 
                               source_dir, 
                               dest_base_dir = "MissingFiles",
                               qseqid_col = "qseqid1", 
                               match_col = "seq_match") {
  
  # Ensure subdirectories exist
  dir.create(file.path(dest_base_dir, "Missing_from_lib1"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(dest_base_dir, "Missing_from_lib2"), recursive = TRUE, showWarnings = FALSE)

  # Clean the qseqid values (remove everything after #)
  df$clean_id <- sub("#.*$", "", df[[qseqid_col]])

  # Get list of all files in the source directory
  all_files <- list.files(source_dir, full.names = TRUE)

  for (i in seq_len(nrow(df))) {
    name <- df$clean_id[i]
    match_type <- df[[match_col]][i]
    match_type <- gsub(" ", "_", match_type)

    # Skip if match_type is not one of the expected values
    if (!match_type %in% c("Missing_from_lib1", "Missing_from_lib2")) {
      next
    }

    # Find matching files (partial match)
    matched_files <- grep(name, all_files, value = TRUE)

    if (length(matched_files) == 0) {
      message(sprintf("No file found for %s", name))
      next
    }

    # Define destination subdirectory
    dest_dir <- file.path(dest_base_dir, match_type)

    # Copy all matching files
    for (file in matched_files) {
      file.copy(file, dest_dir, overwrite = TRUE)
      message(sprintf("Copied %s to %s", basename(file), match_type))
    }
  }
}