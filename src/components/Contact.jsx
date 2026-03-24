import { motion } from 'framer-motion';

export default function Contact() {
  return (
    <section id="contact" className="py-40 px-6 bg-background text-center flex flex-col items-center border-t border-border">
      <div className="max-w-4xl mx-auto w-full">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.8 }}
          className="mb-32 flex flex-col items-center"
        >
          <div className="text-xs uppercase font-bold text-secondaryText tracking-[0.25em] mb-12 border border-border px-8 py-3 rounded-full bg-surface">
            Acquisition Protocol
          </div>
          <h2 className="text-3xl md:text-5xl font-display font-medium text-white leading-relaxed max-w-3xl mb-8 tracking-wide">
            Open to selective discussions with qualified operators, founders, and strategic buyers.
          </h2>
          <p className="text-secondaryText font-normal text-lg tracking-wide">
            A direct and discreet review process is available for aligned buyers.
          </p>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="w-full text-left bg-surface border border-border p-10 md:p-16"
        >
          <div className="mb-14 border-b border-border pb-8">
             <h3 className="text-2xl md:text-3xl font-display font-medium text-white mb-4 tracking-wide">Request Strategic Access</h3>
             <p className="text-secondaryText text-lg font-normal tracking-wide">Reserved for qualified buyers seeking direct discussion regarding Wirebet.com</p>
          </div>

          <form className="grid grid-cols-1 md:grid-cols-2 gap-y-12 gap-x-10" onSubmit={(e) => e.preventDefault()}>
            <div className="space-y-4">
              <label className="text-sm uppercase tracking-[0.15em] font-medium text-secondaryText block">Entity / Fund</label>
              <input type="text" className="w-full bg-surfaceHighlight border border-border px-5 py-5 text-white focus:outline-none focus:border-white/60 focus:bg-surfaceHighlight transition-all duration-500 rounded-none text-lg font-normal tracking-wide" />
            </div>
            <div className="space-y-4">
              <label className="text-sm uppercase tracking-[0.15em] font-medium text-zinc-300 block">Entity / Fund</label>
              <input type="text" className="w-full bg-[#111111] border border-white/20 px-5 py-5 text-white focus:outline-none focus:border-white/60 focus:bg-[#151515] transition-all duration-500 rounded-none text-lg font-normal tracking-wide" />
            </div>
            <div className="space-y-4 md:col-span-2">
              <label className="text-sm uppercase tracking-[0.15em] font-medium text-zinc-300 block">Corporate Email</label>
              <input type="email" className="w-full bg-[#111111] border border-white/20 px-5 py-5 text-white focus:outline-none focus:border-white/60 focus:bg-[#151515] transition-all duration-500 rounded-none text-lg font-normal tracking-wide" />
            </div>
            <div className="space-y-4 md:col-span-2">
              <label className="text-sm uppercase tracking-[0.15em] font-medium text-zinc-300 block">Mandate Type</label>
              <div className="relative">
                <select className="w-full bg-[#111111] border border-white/20 px-5 py-5 text-white focus:outline-none focus:border-white/60 focus:bg-[#151515] transition-all duration-500 appearance-none rounded-none text-lg font-normal tracking-wide outline-none cursor-pointer">
                  <option value="" className="bg-[#151515] text-zinc-300">Select parameter...</option>
                  <option value="acquire" className="bg-[#151515] text-white">Outright Acquisition</option>
                  <option value="partner" className="bg-[#151515] text-white">Strategic Joint Venture</option>
                  <option value="other" className="bg-[#151515] text-white">Capital Allocation</option>
                </select>
                <div className="absolute inset-y-0 right-5 flex items-center pointer-events-none text-white/50">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>
            <div className="space-y-4 md:col-span-2">
              <label className="text-sm uppercase tracking-[0.15em] font-medium text-zinc-300 block">Additional Context</label>
              <textarea rows="3" className="w-full bg-[#111111] border border-white/20 px-5 py-5 text-white focus:outline-none focus:border-white/60 focus:bg-[#151515] transition-all duration-500 resize-none rounded-none text-lg font-normal tracking-wide overflow-hidden"></textarea>
            </div>
            <div className="md:col-span-2 mt-8 flex justify-start border-t border-border pt-12">
              <button type="submit" className="px-16 py-6 bg-white text-black font-semibold tracking-[0.1em] text-sm uppercase hover:bg-zinc-200 transition-colors duration-500 w-full sm:w-auto text-center rounded-none shadow-xl">
                Submit Inquiry
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </section>
  );
}
