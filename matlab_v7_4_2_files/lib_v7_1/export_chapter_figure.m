function export_chapter_figure(h, outDir, baseName)
%EXPORT_CHAPTER_FIGURE Save figure as PNG and PDF with consistent naming.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

set(h, 'PaperPositionMode', 'auto');
saveas(h, fullfile(outDir, [baseName '.png']));
saveas(h, fullfile(outDir, [baseName '.pdf']));

end

