ok I want to trigger firebase event whenever the app functionality was used.

merge pdf - parameter {pdf_page_number_list [12,0 (for image),34,45], time_taken_for_merge}

images to pdf  - parameter {number_of_images, time_taken_for_conversion}

split_pdf - parameter {output_pdf_page_number_list [12, 23, 34, 45, 9], time_taken_for_split}

protect_pdf - parameter {total_page_number , time_taken_for_protection}

unlock pdf - parameter {total_page_number , time_taken_for_protection}

compress pdf -  parameter {total_page_number , time_taken_for_compression}

pdf to iamge - parameter {total_inage , time_taken_for_conversion}

reorder pdf - parameter {total number of pages rotated, total number of pages,  toal number of pages removed, total number of pages swaped, time_taken_for_reordering}

so in the services do firebase event logging. using the event service of firebase.